# == Schema Information
# Schema version: 20090218144012
#
# Table name: donations
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)
#  pitch_id    :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#  purchase_id :integer(4)
#  status      :string(255)     default("unpaid")
#  amount      :decimal(15, 2)
#

class Donation < ActiveRecord::Base

  DEFAULT_AMOUNT = 20

  cattr_reader :per_page
  @@per_page = 10

  include AASM
  class << self
    alias invasive_inherited_from_aasm inherited
    def inherited(child)
      invasive_inherited_from_aasm(child)
      super
    end
  end
  aasm_column :status
  aasm_initial_state  :unpaid

  aasm_state :unpaid
  aasm_state :paid
  aasm_state :refunded

  aasm_event :pay do
    transitions :from => :unpaid, :to => :paid 
  end

  aasm_event :refund do
    transitions :from => :paid, :to => :refunded
  end

  belongs_to :user
  belongs_to :pitch
  belongs_to :purchase
  belongs_to :group
  validates_presence_of :pitch_id
  validates_presence_of :user_id
  validates_presence_of :amount
  validates_numericality_of :amount, :greater_than => 0
  validate_on_update :disable_updating_paid_donations, :check_donation, :if => lambda { |me| me.pitch }
  validate_on_create :check_donation, :if => lambda { |me| me.pitch }

  named_scope :unpaid, :conditions => "status = 'unpaid'"
  named_scope :paid, :conditions => "status = 'paid'"
  named_scope :from_organizations, :include => :user, :conditions => "users.type = 'organization'"
  named_scope :for_pitch, lambda {|pitch| { :conditions => {:pitch_id => pitch.id} } }
  named_scope :by_user, lambda {|user| { :conditions => {:user_id => user.id} } }

  after_save :update_pitch_funding, :send_thank_you, :if => lambda {|me| me.paid?}

  def self.createable_by?(user)
    user
  end

  # TODO: remove this 'bandaid' method when conversion complete
  def amount_in_cents
    return 0 if amount.nil?
    (amount * 100).to_i
  end

  def editable_by?(user)
    self.user == user
  end

  def deletable_by?(user)
    return false if user.nil?
    (user.admin? || self.user == user) && !self.paid? 
  end

  protected

  def send_thank_you
    Mailer.deliver_user_thank_you_for_donating(self)
  end

  def update_pitch_funding
    pitch.current_funding += amount
    pitch.save
  end

  def disable_updating_paid_donations
    if paid? && !being_marked_as_paid?
      errors.add_to_base('Paid donations cannot be updated')
    end
  end

  def being_marked_as_paid?
    status_changed? && status_was == 'unpaid'
  end

  def check_donation
    if pitch.fully_funded?
      errors.add_to_base("Great news! This pitch is already fully funded therefore it can't be donated to any longer.")
      return
    end

    #TODO: convert user_can_donate_more? to use BigDecimal and pass in amount
    unless pitch.user_can_donate_more?(user, amount)
      errors.add_to_base("Thanks for your support but we only allow donations of 20% of requested amount from one user. Please lower your donation amount and try again.")
    end
  end
end

