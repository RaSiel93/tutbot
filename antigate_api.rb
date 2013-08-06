require 'net/http'
require 'net/http/post/multipart'

def send_captcha( key, captcha_file )
  uri = URI.parse( 'http://antigate.com/in.php' )
  file = File.new( captcha_file, 'rb' )
  req = Net::HTTP::Post::Multipart.new( uri.path,
                                        :method => 'post',
                                        :key => key,
                                        :file => UploadIO.new( file, 'image/jpeg', 'image.jpg' ),
                                        :regsense => 1,
                                        :is_russian => 1
                                         )
  http = Net::HTTP.new( uri.host, uri.port )
  begin
    resp = http.request( req )
  rescue => err
    puts err
    return nil
  end#begin
  
  id = resp.body
  return id[ 3..id.size ]
end#def

def get_captcha_text( key, id )
  data = { :key => key,
           :action => 'get',
           :id => id,
           :min_len => 1,
           :max_len => 10 }
  uri = URI.parse('http://antigate.com/res.php' )
  req = Net::HTTP::Post.new( uri.path )
  http = Net::HTTP.new( uri.host, uri.port )
    req.set_form_data( data )

  begin
    resp = http.request(req)
  rescue => err
    puts err
    return nil
  end


  text = resp.body
  if text != "CAPCHA_NOT_READY"
    return text[ 3..text.size ]
  end#if
  
  if text.start_with?("ERROR")
    return nil
  end

  return nil
end#def

def report_bad( key, id )
  data = { :key => key,
           :action => 'reportbad',
           :id => id }
  uri = URI.parse('http://antigate.com/res.php' )
  req = Net::HTTP::Post.new( uri.path )
  http = Net::HTTP.new( uri.host, uri.port )
  req.set_form_data( data )

  begin
    resp = http.request(req)
  rescue => err
    puts err
  end
end#def