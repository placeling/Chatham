namespace "blogger" do

  desc "Load a list of place urls and put them into blogger models"
  task :load, [:file_path] => :environment do |t, args|
    line_num=0
    filename = Rails.root + args.file_path
    puts "Slurping #{filename}"

    created_count = 0

    text=File.open(filename).read
    text.each_line do |line|
      line = line.strip
      if line[-1] != "/"
        line = line + "/"
      end

      puts "#{line_num += 1} #{line}"

      blogger = Blogger.find_by_url(line)

      if blogger.nil?
        Blogger.create!(:url => line)
        created_count += 1
      end
    end

    puts "Created #{created_count} bloggers"
  end

end