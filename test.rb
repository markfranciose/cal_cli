# THIS IS A CANVAS... 

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'


# helpers
def write_to_yaml(path, hash)
    File.open(path, "w") do |file|
       file.write(hash.to_yaml) 
    end
end

class Account

    attr_accessor :name, :current_token, :service, :argvs
       
    YAML_PATH = "config.yml"
    # constants 
    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
    APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'.freeze
    CREDENTIALS_PATH = 'creds.json'.freeze
    TOKEN_PATH = 'token.yaml'.freeze
    # I think we always want this scope.
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_EVENTS

    # on init, we want to check the config.yml and see if there's a default alias/account.
    # if so, we want to use that account as the path for the creds.
    # if not, we want to run the new alias/account creation
    def initialize
        # what needs to be defined here to allow for two different accounts to be used?
        # @token_path = "test" # creds.token_path + "-token.yaml".freeze || ""
        service = Google::Apis::CalendarV3::CalendarService.new
        service.client_options.application_name = APPLICATION_NAME
        @argvs = ARGV
        set_token
        add_account if !set_token
        service.authorization = authorize

        @service = service
        run_flag

    end 

    def run_flag
        puts "we run"
        show_today if @argvs[0] == "-t"
    end

    def show_today
       now = DateTime.now
       time_max = DateTime.new(now.year, now.month, now.day, 11, 59, 59,now.zone)
       response = @service.list_events("primary",
                               max_results: 250,
                               single_events: true,
                               order_by: 'startTime',
                               time_max: time_max.iso8601,
                               time_min: now.iso8601)
puts 'Upcoming events:'
puts 'No upcoming events today' if response.items.empty?
response.items.each do |event|
  start = event.start.date || event.start.date_time
  puts "- #{event.summary} (#{start})"
end

    end

    private 

    def add_account
        puts "There are no accounts saved"
        puts "What is the alias of the account?"
        account_alias = gets.chomp
        set_default(account_alias)
    end

    def set_token
        # check the yaml, see what the default is.
        config_yaml =  YAML.load_file(YAML_PATH)
        @current_token = config_yaml["default"]
    end 

    def set_default(account_alias)
        # load config yaml 
        config_yaml = YAML.load_file(YAML_PATH)
        config_yaml["default"] = account_alias
        
        @current_token = account_alias
        write_to_yaml(YAML_PATH, config_yaml)
    end

        def authorize
                client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
                token_store = Google::Auth::Stores::FileTokenStore.new(file: "#{@current_token}.yaml")
                authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
                user_id = 'default'
                credentials = authorizer.get_credentials(user_id)
          if credentials.nil?
            url = authorizer.get_authorization_url(base_url: OOB_URI)
            puts 'Open the following URL in the browser and enter the ' \
                 "resulting code after authorization:\n" + url
            code = $stdin.gets
            credentials = authorizer.get_and_store_credentials_from_code(
              user_id: user_id, code: code, base_url: OOB_URI
            )
          end
          credentials
        end

    
end

cool = Account.new

# Initialize the API
=begin
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize
=end

def format_input_time input
        now = DateTime.now
        DateTime.new(now.year, now.month, now.day, input[0].to_i, input[1].to_i, 0, -5)
end

def get_activity
        puts "enter activity"
        gets.chomp
end

def get_start_time
        puts "Enter start time"
        input = gets.chomp 
        input = input.split(" ")
        return DateTime.now if input == ""
        format_input_time(input)
end

def get_end_time
        puts "Enter end time"
        input = gets.chomp
        input = input.split(" ")
        return DateTime.now if input.length < 2
        format_input_time input
end

#start_time = get_start_time
#end_time = get_end_time
#activity = get_activity

def create_event start_time, end_time, activity
        Google::Apis::CalendarV3::Event.new(
                summary: activity,
                start: {
                        date_time: start_time
                },
                end: {
                        date_time: end_time
                })
end

# event = create_event start_time, end_time, activity


=begin
event = Google::Apis::CalendarV3::Event.new(
        summary: 'this is a test',
        start: {date_time: DateTime.now},
        end: {date_time: DateTime.now}
)
=end

# cool = service.insert_event('primary', event)

