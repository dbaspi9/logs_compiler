module LogsPrinter
  $LOAD_PATH << "."

  require "logs_compiler"

  @logs_compiler = LogsCompiler.new

  @logs_compiler.print_varnish_logs
  @logs_compiler.print_xml_logs
  @logs_compiler.print_json_logs
end
