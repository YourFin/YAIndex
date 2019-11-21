class FilesController < ApiController
  def list
    render json: Dir.glob("#{ENV["FILES_DIRECTORY"]}/**/*").map { |filepath|
      filepath.gsub(Regexp.new("^#{Regexp.escape(ENV["FILES_DIRECTORY"])}"), '')
    }
  end

  private
  # Given path relative to root
  def build_file_tree(relative_path)
    rel_path = Pathname.new(relative_path)
    raise ApiError::Forbidden.new unless verify_path_in_scope(rel_path)

  end

  # Takes as string and makes sure that it isn't escaping the context browser
  # is limited to
  SYSTEM_ROOT_PATH = Pathname.new('/')
  def verify_path_in_scope(path)
    browser_root_path = Pathname.new(ENV["FILES_DIRECTORY"])
    while path != browser_root_path
      if ROOT_PATH == path
        return false
      end
    end
    true
  end

  # Lists the files relative to relative_root
  # I.e. if relative_root is /bar and ENV["FILES_DIRECTORY"] is /foo
  # then this will return the files under /foo/bar
  # WARNING: relative_root MUST NOT ESCAPE BROWSER ROOT
  def list_files(relative_root)
    Dir.glob("#{ENV["FILES_DIRECTORY"]}/**/*")
      .map { |file_path_str| Pathname.new(file_path_str) }
  end

  @directory_regex = Regexp.new("$#{Regexp.escape(ENV["FILES_DIRECTORY"])}")
end
