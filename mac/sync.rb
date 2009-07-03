require 'fileutils'
require 'logger'

@logger = Logger.new('installd.log')

begin

  FileUtils.rm_rf('unzipped')
  FileUtils.mkdir_p('unzipped')

  apps_pattern = File.join(ENV['HOME'], 'Music', 'iTunes', 'Mobile Applications', '*.ipa')

  def execute(command)
    @logger.info command
    @logger.info `#{command}`
    unless $?.success?
      message = "Error executing command: #{command}"
      @logger.error message
      raise message
    end
  end

  doc = ''
  Dir[apps_pattern].each do |app_file|
    app_name = File.basename(app_file, '.ipa')
    unzip_dir = File.join('unzipped', app_name)
    plist = File.join(unzip_dir, 'iTunesMetadata.plist')
    
    execute %{/usr/bin/unzip -d "#{unzip_dir}" "#{app_file}" iTunesMetadata.plist}
    execute %{/bin/chmod +rw "#{plist}"}
    execute %{/usr/bin/plutil -convert xml1 "#{plist}"}

    File.open(plist) do |file|
      file.readline
      file.readline
      doc << file.read
    end
  end

  FileUtils.rm_rf('unzipped')

  require 'net/http'
  require 'uri'

  @logger.info "*** Sync begins ***"
  
  response = Net::HTTP.post_form(URI.parse('http://installd.local/users/floehopper/installs/synchronize'), { '_method' => 'put', 'doc' => doc })
  unless response.code == '200'
    raise "Unexpected response code: #{response.code}"
  end
  
  @logger.info "*** Sync ends ***"

rescue => exception
  @logger.error exception
end