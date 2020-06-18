class Script < ApplicationRecord
    extend FriendlyId
    
    friendly_id :slug_candidates, use: :slugged

    validates :name, :body, presence: true

    def screenshot
        "/screenshots/#{self.slug}.png"
    end

private
    def slug_candidates
      [SecureRandom.uuid]
    end
  
end
