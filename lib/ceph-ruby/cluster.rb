module CephRuby
  class Cluster
    attr_accessor :handle

    def initialize(config_path = "/etc/ceph/ceph.conf")
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_create(handle_p, nil)
      raise SystemCallError.new("open of cluster failed", -ret) if ret < 0
      self.handle = handle_p.get_pointer(0)

      setup_using_file(config_path)

      connect

      if block_given?
        yield(self)
        shutdown
      end
    end

    def shutdown
      return unless handle
      Lib::Rados.rados_shutdown(handle)
      self.handle = nil
    end

    def pool(name, &block)
      Pool.new(self, name, &block)
    end

    # helper methods below

    def connect
      ret = Lib::Rados.rados_connect(handle)
      raise SystemCallError.new("connect to cluster failed", -ret) if ret < 0
    end

    def setup_using_file(path)
      ret = Lib::Rados.rados_conf_read_file(handle, path)
      raise SystemCallError.new("setup of cluster from config file '#{path}' failed", -ret) if ret < 0
    end
  end
end
