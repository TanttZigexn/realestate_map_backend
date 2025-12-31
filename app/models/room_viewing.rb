class RoomViewing < ApplicationRecord
  belongs_to :room

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A[0-9+\-\s()]+\z/ }
  validates :preferred_date, presence: true
  validates :status, inclusion: { in: %w[pending confirmed cancelled completed] }

  validate :preferred_date_in_future
  validate :preferred_date_not_too_far

  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :by_room, ->(room_id) { where(room_id: room_id) }
  scope :upcoming, -> { where('preferred_date >= ?', Time.current) }
  scope :past, -> { where('preferred_date < ?', Time.current) }

  private

  def preferred_date_in_future
    return unless preferred_date.present?

    if preferred_date < Time.current
      errors.add(:preferred_date, 'must be in the future')
    end
  end

  def preferred_date_not_too_far
    return unless preferred_date.present?

    max_days = 90
    if preferred_date > max_days.days.from_now
      errors.add(:preferred_date, "cannot be more than #{max_days} days in the future")
    end
  end
end

