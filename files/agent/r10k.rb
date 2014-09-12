module MCollective
  module Agent
    class R10k<RPC::Agent
       ['push',
        'pull',
        'status'].each do |act|
          action act do
            validate :path, :shellsafe
            path = request[:path]
            reply.fail "Path not found #{path}" unless File.exists?(path)
            return unless reply.statuscode == 0
            run_cmd act, path
            reply[:path] = path
          end
        end
        ['cache',
         'synchronize',
         'deploy',
         'sync'].each do |act|
          action act do
            if act == 'deploy'
              validate :environment, :shellsafe
              environment = request[:environment]
              run_cmd act, environment
              reply[:environment] = environment
            else
              run_cmd act
            end
          end
        end
      private

      def run_cmd(action,arg=nil)
        output = ''
        git  = ['/usr/bin/env', 'git']
        r10k = ['/usr/bin/env', 'r10k']
        case action
          when 'push','pull','status'
            cmd = git
            cmd << 'push'   if action == 'push'
            cmd << 'pull'   if action == 'pull'
            cmd << 'status' if action == 'status'
            reply[:output] = run(cmd, :stderr => :error, :stdout => :output, :chomp => true, :cwd => arg )
          when 'cache','synchronize','sync', 'deploy'
            cmd = r10k
            cmd << 'cache' if action == 'cache'
            cmd << 'deploy' << 'environment' << '-p' if action == 'synchronize' or action == 'sync'
            if action == 'deploy'
              cmd << 'deploy' << 'environment' << arg << '-p'
            end
            reply[:output] = run(cmd, :stderr => :error, :stdout => :output, :chomp => true)
        end
      end
    end
  end
end
