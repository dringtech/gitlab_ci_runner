Puppet::Type.type(:gitlab_runner).provide(:linux_gitlab_runner) do
  desc "Configure a Gitlab CI Runner"

  commands :gitlab_runner => '/usr/bin/gitlab-runner'

  def exists?
    begin
      runners = get_runners
      runners.each do |runner|
        if resource[:name] == runner[0]
          if verify_runner(runner[2]) == true
            return true
          end
        end
      end
      return false
    rescue Puppet::ExecutionFailure => e
      fail("Error getting runner")
    end
  end



  def create
    begin
      #gitlab_runner('register', '--non-interactive', '--url ', resource[:url], '--registration-token', resource[:token])
      if @resource[:executor] == 'docker'
        cmd = "gitlab-runner register --non-interactive --name #{@resource[:name]} --url #{@resource[:url]} --registration-token #{@resource[:token]} --executor  #{@resource[:executor]} --docker-image #{@resource[:docker_image]} --tag-list #{@resource[:tags]}"
      else
        cmd = "gitlab-runner register --non-interactive --name #{@resource[:name]} --url #{@resource[:url]} --registration-token #{@resource[:token]} --executor  #{@resource[:executor]} --tag-list #{@resource[:tags]} "
      end
      #Puppet.notice("Running command to create runner: #{cmd}")
      Open3.popen2(cmd) do |stdin, stderr,  wait_thr|
        return_value = wait_thr.value
        if return_value.exitstatus > 0
          fail("Cannot create runner #{@resource[:name]}")
          break
        end
      end
    rescue Puppet::ExecutionFailure => e
    end
    exists?
  end


  def destroy
    unregister_runner(resource[:name])
  end


  def unregister_runner(runner_to_unreg)
    runners = get_runners
    runners.select { |x| x[0] == runner_to_unreg }.each do |runner|
      runner_token = runner[1]
      runner_url = runner[3]
      cmd = "gitlab-runner unregister --url #{runner_url} --token #{runner_token}"
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        while line = stderr.gets
          p "deleting: #{runner_token}"
          p line
        end
      end
    end
  end

  def verify_runner(token)
    thetoken = nil
    cmd = "gitlab-runner verify"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stderr.gets
        if line.to_s.match(/#{token}/)
          x = line.split()
          thetoken = x[5][12,8]#.tr("\e[;m",'')
          if thetoken.to_s == token.to_s
            return true
          else
            next
          end
        end
      end
    end
  end

  def get_runners
    runner_list = []
    runner_entry = []
    cmd = "gitlab-runner list"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stderr.gets
        x = line.split()
        if x[0].to_s != /^Listing/
          runner_name = x[0].tr("\e[;",'')
          runner_token = x[3].gsub(/Token\e\[0;m=/,'')
          runner_token_short = runner_token[0,8]
          runner_url = x[4].tr("URL\e[0;m=",'')
          runner_entry = [runner_name, runner_token, runner_token_short, runner_url]
          runner_list.push(runner_entry)
        end
      end
    end
    return runner_list[1..runner_list.length]
  end

  def check_service
    result = ""
    cmd = "gitlab-runner status"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stderr.gets
        x = line.split()
        if x[3].to_s == "not" and x[4] == "installed."
          result = "not_installed"
        elsif x[3].to_s == "not" and x[4] == "running."
          result = "stopped"
        end
      end
      if stdout.gets
        result = "running"
      end
      return result
    end
  end


end
