require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'

Encoding.default_external = 'UTF-8'


API_KEY = '***'
USER_ID = 'keim_at_si'
PROXY = ''


def download(url, filename)
  begin
  open(url, {proxy:PROXY}) do |bin|
    File.binwrite(filename, bin.read)
  end
  rescue => error
    p error.message
  end
end


def listAllCodeID(pageStart, pageMax)
  codeIDList = []
  page = pageStart
  loop do
    api_url = "http://wonderfl.net/user/#{USER_ID}/codes?page=#{page}"
    open(api_url, {proxy:PROXY}) do |file|
      html = Nokogiri::HTML(file)
      if pageMax == 0
        codelink = html.xpath('//*[@id="boxProfInfo"]/ul/li[1]/a') 
        pageMax = ((codelink.text[/\d+/].to_i + 11) / 12).to_i + 1
      end
      nodeSet = html.xpath('//*[@id="sectActivity"]/div[2]').xpath('./div')
      nodeSet.each do |node|
        codeID = node['id'].match(/^code_([0-9a-zA-Z]+)/)[1]
        codeIDList << codeID
      end
      sleep 1
    end
    page += 1
    p "#{page-1}/#{pageMax-1}"
    break if page == pageMax
  end
  codeIDList
end


def downloadCodeData(id, forceOverwrite)
  api_url = "http://api.wonderfl.net/code/#{id}?api_key=#{API_KEY}"
  dirname = ''
  open(api_url, {proxy:PROXY}) do |file|
    jsonString = file.read
    codeData = JSON.parse(jsonString)['code']

    date = Time.at(codeData['created_date']).strftime('%Y%m%d')
    name = codeData['as3'].match(/public\sclass\s([0-9a-zA-Z$_]+)/)[1]
    safename = codeData['title'].gsub(/[*?"|:><\s\\\/]+/, '_')
    dirname = "./projects/#{date}_#{safename}"

    if File.exist?(dirname)
      if forceOverwrite
        FileUtils.rm(Dir.glob("#{dirname}/*"))
      else 
        return
      end
    else 
      Dir.mkdir(dirname) 
    end

    readme_stat = [codeData['title'], id, codeData['favorite_count'], codeData['forked_count'], codeData['license']]
    readme_text = "# [%s](http://wonderfl.net/c/%s)\n\nfavorite:%s / forked:%s / license:%s\n\n![thumbnail](./thumbnail.jpg)" % readme_stat

    File.write("#{dirname}/README.md", readme_text)
    File.write("#{dirname}/api_response.json", jsonString)
    File.write("#{dirname}/#{name}.as", codeData['as3'])
    download(codeData['swf'], "#{dirname}/#{name}.swf")
    download(codeData['thumbnail'].sub('_100',''), "#{dirname}/thumbnail.jpg")
  end
  dirname
end


# Get them
listAllCodeID(1,0).each do |codeID|
  p downloadCodeData(codeID, true)
  sleep 1
end