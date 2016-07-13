Puppet::Type.type(:gitlab_runner).provide(:linux_gitlab_runner) do
  desc "Configure a Gitlab CI Runner"

  commands :gitlab_runner => '/usr/bin/gitlab-runner'

  def create
    begin
      register_runner
    rescue Puppet::ExecutionFailure => e
      fail("Error creating runner : #{e}")
    end
    exists?
  end

  def destroy
    begin
      unregister_runner
    rescue Puppet::ExecutionFailure => e
      fail("Error creating runner : #{e}")
    end
  end

  def exists?
    begin
      runners = get_runners
      if runners.nil?
        return false
      else
        return runners.any? do |h|
          h[:name] == resource[:name]
        end
      end
    rescue Puppet::ExecutionFailure => e
      fail("Error getting runner : #{e}")
    end
  end

  def register_runner
    if @resource[:executor] == 'docker'
      cmd = "gitlab-runner register --non-interactive --name #{@resource[:name]} --url #{@resource[:url]} --registration-token #{@resource[:token]} --executor  #{@resource[:executor]} --docker-image #{@resource[:docker_image]} --tag-list #{@resource[:tags]}"
    else
      cmd = "gitlab-runner register --non-interactive --name #{@resource[:name]} --url #{@resource[:url]} --registration-token #{@resource[:token]} --executor  #{@resource[:executor]} --tag-list #{@resource[:tags]} "
    end
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      return_value = wait_thr.value
      stderr.read.split("\n").each { |x| info(x) }
      if return_value.exitstatus > 0
        fail("Cannot create runner #{@resource[:name]}")
      end
    end
  end

  def unregister_runner
    cmd = "gitlab-runner unregister --name #{resource[:name]}"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      return_value = wait_thr.value
      stderr.read.split("\n").each { |x| info(x) }
      if return_value.exitstatus > 0
        fail("Cannot unregister runner #{@resource[:name]}")
      end
    end
  end

  def verify_runner(token)
    cmd = "gitlab-runner verify"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stderr.gets
        if line.to_s =~ /#{token[0,8]}/
          return true
        else
          next
        end
      end
      return false
    end
  end

  def get_runners
    runner_list = []
    cmd = "gitlab-runner list"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stderr.gets
        if line !~ /^Listing/
          line.delete! "\e\[0;m"
          x = line.split
          runner = {
            :name => x[0],
            :token => x[2].gsub(/.+?=/,''),
            :url => x[3].gsub(/.+?=/,''),
          }
          runner_list.push(runner)
        end
      end
    end
    return runner_list
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
