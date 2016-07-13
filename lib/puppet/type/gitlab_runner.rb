Puppet::Type.newtype(:gitlab_runner) do

  desc 'runner manages the Gitlab-ci multi-runner'

  ensurable

  newparam(:name, :namevar => true) do
    isrequired
  end

  newparam(:url) do
    isrequired
  end

  newparam(:tags, :array_matching => :all) do
    isrequired
  end

  newparam(:token) do
    isrequired
  end

  newparam(:docker_image) do
  end

  newparam(:executor) do
    isrequired
    validate do |value|
      if value == 'docker'
        fail Puppet::Error, "Docker executor needs docker_image parameter" unless !@resource[:docker_image].nil?
      end
    end
  end

end
