namespace :spree do
  namespace :gift_card do
    desc 'Send GiftCard Emails'
    task send_emails: :environment do
      SpreeGiftCard::SendEmailJob.perform_now
    end

    desc 'Schedule: Send GiftCard Emails'
    task schedule_send_emails: :environment do
      SpreeGiftCard::SendEmailJob.perform_later
    end
  end
end
