#!/usr/bin/env ruby

require 'action_mailer'
require_relative 'environment'  # Load @config from config.yml

class Mailer < ActionMailer::Base
  default from: 'Sensr Watcher <nodeops@cppwind.com>'

  raise_delivery_errors = true
  delivery_method       = @config.delivery_method
  smtp_settings         = {
    address:              @config.address,
    authentication:       @config.auth,
    ca_file:              @config.ca_file,
    domain:               @config.domain,
    enable_starttls_auto: @config.enable_starttls_auto,
    openssl_verify_mode:  @config.ssl_verify,
    password:             @config.password,
    port:                 @config.port,
    user_name:            @config.username
  }

  def notification(client, hours, recipients, *proof)
    mail(
      to: recipients,
      subject: "SensrWatcher - #{client} #{proof.first}: #{hours}hrs since last update"
    ) do |format|
      if proof.first.match?('proof')
        format.html { "<span>#{client} has not updated <code>proof#{proof.first.to_s.gsub('proof', '')}.md</code> in #{hours} hours.</span>" }
      elsif proof.first.match?('data')
        format.html { "<span>#{client} has not updated data in #{hours} hours.</span>" }
      else
        format.html { "<span>Something went wrong, please check the notifier.</span>" }
      end
    end
  end
end

## Usage:
# email = Mailer.notification('Derpious', '7', 'eeccher@cppwind.com')
# puts email
# email.deliver! && ( puts "Message Sent!" )
