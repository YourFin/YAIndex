class FilesController < ApiController
  def list
    render json: file_tree("")
  end

  private
  # Given path relative to root
  def file_tree(path_str)
    uncleaned_path = build_system_path(path_str)
    raise ApiError::Forbidden.new unless verify_path_in_scope(uncleaned_path)
    cleaned_path = uncleaned_path.realpath
    return build_directory_tree(cleaned_path)[:children]
  end

  def build_system_path(request_path_str)
    Pathname.new(ENV["FILES_DIRECTORY"]) + request_path_str
  end

  # Takes as string and makes sure that it isn't escaping the context browser
  # is limited to
  SYSTEM_ROOT_PATH = Pathname.new('/')
  def verify_path_in_scope(path)
    browser_root_path = Pathname.new(ENV["FILES_DIRECTORY"]).realpath
    path = begin
      path.realpath
    rescue
      return false
    end
    p path
    while path != browser_root_path
      if SYSTEM_ROOT_PATH == path
        return false
      end
      path = path.dirname
    end
    true
  end

  MILLISECONDS_PER_SECOND = 1000
  def build_directory_tree(path)
    return nil unless path.exist? && path.readable?
    if path.file?
      return {
        :size => path.size,
        :modified => path.stat.ctime.to_i * MILLISECONDS_PER_SECOND,
        :name => path.basename,
      }
    elsif path.directory?
      return {
        :name => path.basename,
        :modified => path.stat.ctime.to_i * MILLISECONDS_PER_SECOND,
        :children => Dir.glob(path + "*").map { |path_str|
          build_directory_tree(Pathname.new(path_str))
        }.compact
      }
    else # Ignore symlinks, hardlinks, etc.
      return nil
    end
  end

  # Lists the files relative to relative_root
  # I.e. if relative_root is /bar and ENV["FILES_DIRECTORY"] is /foo
  # then this will return the files under /foo/bar
  # WARNING: relative_root MUST NOT ESCAPE BROWSER ROOT
  def list_files(relative_root)
    Dir.glob("#{ENV["FILES_DIRECTORY"]}/**/*")
      .map { |file_path_str| Pathname.new(file_path_str) }
  end
end
