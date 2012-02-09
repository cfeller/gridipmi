#require 'irb/completion'
require 'rubygems'
require 'wirble'
wirble_opts = {
	:skip_prompt => true
}
Wirble.init(wirble_opts)
Wirble.colorize
