require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'
require 'optparse'

Encoding.default_external = 'UTF-8'



# Option
$user = 'keim_at_si'  # user name
$type = 'codes'       # codes or favorites
$first_page = 1       # first page
$last_page = 0        # last page 
$dirName = 'projects' # save directory
$accessInterval = 1   # 1 second interval for each access
$option = {}          # network option (like proxy)

OptionParser.new do |opt|
  opt.on('-u VAL')     {|u| $user = usr}
  opt.on('-fav')       {|v| $type = 'favorites'}
  opt.on('-first VAL') {|f| $first_page = f.to_i}
  opt.on('-last VAL')  {|l| $last_page = l.to_i}
  opt.on('-dir VAL')   {|d| $dirName = d}
  opt.on('-interval VAL') {|i| $accessInterval = i.to_i}
  opt.parse!(ARGV)
end


def download(url, filename)
  begin
  open(url, $option) do |bin|
    File.binwrite(filename, bin.read)
  end
  rescue => error
    p error.message
  end
end


def listAllCodeID(userID, type, pageStart, pageMax)
  api_url = "http://wonderfl.net/user/#{userID}/#{type}?page="

  codeIDList = []
  page = pageStart
  loop do
    open(api_url + page.to_s, $option) do |file|
      html = Nokogiri::HTML(file)
      if pageMax == 1
        codelink = html.xpath('//*[@id="boxProfInfo"]/ul/li[1]/a') 
        pageMax = ((codelink.text[/\d+/].to_i + 11) / 12).to_i + 1
      end
      nodeSet = html.xpath('//*[@id="sectActivity"]/div[2]').xpath('./div')
      nodeSet.each do |node|
        codeID = node['id'].match(/^code_([0-9a-zA-Z]+)/)[1]
        codeIDList << codeID
      end
      sleep $accessInterval
    end
    page += 1
    p "#{page-1}/#{pageMax-1}"
    break if page == pageMax
  end
  codeIDList
end


def downloadCodeData(id, forceOverwrite)
  api_url = "http://wonderfl.net/c/#{id}"

  dirName = ''
  open(api_url, $option) do |file|
    html = Nokogiri::HTML(file)
    header = html.xpath('//*[@id="content"]/article/header/div')

    title       = header.xpath('h1').text
    description = header.xpath('p[@class="description"]').text.gsub("\n", "  \n")
    codeData    = html.xpath('//*[@id="raw_as3"]').text
    forkCount   = header.xpath('ul/ul/li[1]').text[/\d+/]
    favCount    = header.xpath('ul/ul/li[2]').text[/\d+/]
    modDate     = header.xpath('ul/ul/li[5]').text[/\d{4}-\d{2}+-\d{2}/].gsub('-','')
    thumbnail   = html.xpath('//*[@id="swf"]/img/@src').text.sub(/\?.*$/, '')

    classNameHolder = codeData.match(/public\sclass\s([0-9a-zA-Z$_]+)/)
    if classNameHolder.nil?
      className = id
      codeExt = '.mxml'
    else 
      className = classNameHolder[1]
      codeExt = '.as3'
    end


    swfURL      = thumbnail.sub('wonderfl.net/images/capture', 'swf.wonderfl.net/swf/usercode').sub('jpg','swf')
    safeName    = title.gsub(/[*?"'|:><\s\\\/]+/, '_')
    dirName     = "./#{$dirName}/#{modDate}_#{safeName}"

    if File.exist?(dirName)
      if forceOverwrite
        FileUtils.rm(Dir.glob("#{dirName}/*"))
      else 
        return
      end
    else 
      Dir.mkdir(dirName) 
    end

    readme_stat = [title, id, favCount, forkCount, description]
    readme_text = "# [%s](http://wonderfl.net/c/%s)\n\nfavorite:%s / forked:%s\n\n%s\n\n![thumbnail](./thumbnail.jpg)" % readme_stat

    File.write("#{dirName}/README.md", readme_text)
    File.write("#{dirName}/#{className}.#{codeExt}", codeData)
    download(swfURL, "#{dirName}/#{className}.swf")
    download(thumbnail.sub('_100',''), "#{dirName}/thumbnail.jpg")
  end
  dirName
end


# Get them
Dir.mkdir($dirName) if !File.exist?($dirName)


listAllCodeID($user, $type, $first_page, $last_page+1).each do |codeID|
  p downloadCodeData(codeID, true)
  sleep $accessInterval
end

