require "ec2/writer/version"

require 'aws-sdk-ec2'

module Ec2
  module Writer
    class Runner
      WRITE_MODE = 'a'.freeze
      TEMP_IP = '0.0.0.0'
      # desc "write_config file_name host_prefix welligence_ml 2 10 ubuntu ~/.ssh/welligence.pem", "In ~/.ssh/config, mae add this line: `Include <where to run this command>/file_name`"

      def write_config(file_name = 'ec2.d', host_prefix = 'welligence_ml', first = 2, last = 10, user = 'ubuntu', identity_file = '~/.ssh/welligence.pem' )
        ec2 = Aws::EC2::Resource.new(region: 'us-west-2')
        filepath = "#{Dir.pwd}/#{file_name}"
        FileUtils.rm_rf filepath
        FileUtils.touch filepath

        ec2.instances({filters: [{name: 'tag:Name', values: first.upto(last).map{|i| "#{host_prefix}_#{i}"} }]}).each do |i|
          instance_tag_name = i.tags.map(&:value).join()
          public_ip_address = i.public_ip_address

          puts "#{instance_tag_name} - #{public_ip_address}"
          File.open(filepath, WRITE_MODE) { |f| f << ssh_host(host: instance_tag_name, host_name: public_ip_address, user: user, identity_file: identity_file) }
        end
      end

      private

      def ssh_host(host:, host_name:, user:, identity_file:)
        %{
  # #{host}
  Host #{host}
  HostName #{host_name || TEMP_IP}
  User #{user}
  IdentityFile #{identity_file}
        }
      end
    end
  end
end

