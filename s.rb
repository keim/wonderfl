Dir.glob("./projects/*") do |path|
	title = path.match(/[^\/]+$/)[0]
	puts '<a href="' + path + '">' + title + '</a>'
end