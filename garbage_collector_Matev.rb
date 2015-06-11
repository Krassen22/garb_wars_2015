require 'open-uri'
require 'net/http'


HOST_URL = "http://192.168.41.128:8080/"
COMPANY_NAME = "Krassen_Angelov"

def get_objects id
  edges = Array.new
  url = HOST_URL + "/api/sector/#{id}/objects"
  puts "All objects from sector #{id}."
  p url; puts "\n"
  response = open(url).read
  # p response
  edges = response.lines
end

def get_roots id
  roots = Array.new
  int_str_roots = Array.new
	url = HOST_URL + "/api/sector/#{id}/roots"
  puts "All roots from sector #{id}."
	p url; puts "\n"
  response = open(url).read
  # p response
  p roots = response.lines
  roots.each do |root|
    root = root.to_i.to_s
    int_str_roots << root
  end
  return int_str_roots
end

def vertices_map edges
  vertices_hash = Hash.new{|h,k| h[k] = []}
  vertex = nil
  edges.each do |edge|
    f_vertex = edge.split(" ")[0]
    s_vertex = edge.split(" ")[-1]
    if vertex != f_vertex
      vertex = f_vertex
    end
    vertices_hash[vertex] << s_vertex
  end
  return vertices_hash
end

class Array2D < Array
  def [](n)
    self[n]=Array.new if super(n) == nil
    super n
  end
end

def extirpate_roots all_hash_vertices, all_roots, id
  #for id in 1..10
    cheker1 = 0
    cheker2 = 0
    all_roots[id].each do |root|
      all_hash_vertices[id].each do |key, value|
        if root == key
          p "ID #{id}"
          p root
          all_roots[id] << value
          all_roots[id].flatten!
          all_hash_vertices[id].delete key
          cheker1 = 1
        end
        value.each do |v|
          if root.eql? v
            value.delete(root)
            cheker2 = 1
          end
        end
      end
    end
    return all_hash_vertices if cheker1 == 0 && cheker2 == 0
  #end
  extirpate_roots all_hash_vertices, all_roots, id
end

def find_start_points all_hash_vertices, id
  cheker = 0
  index = 0
  #start_points = Array2D.new
  start_points = Array.new
  all_hash_vertices[id].each do |key1, value1|
    all_hash_vertices[id].each do |key2, value2|
      value2.each do |v2|
        if key1 == v2
         cheker = 1
         break
        end
      end
      break if cheker == 1
    end
    if cheker == 0
      #start_points[index] << key1
      start_points << key1
      p start_points
      puts "------------------"
      index += 1
    end
    cheker = 0
  end
  return start_points
end

$trajectories = Array2D.new
$index_tra = 0;

def exist value
  $trajectories.each do |trajectory|
    if trajectory == nil
      next
    end
    trajectory.each do |tra|
      if tra == value
        return true
        break
      end
    end
  end
  return false
end


def create_trajectories_recursion all_hash_vertices, key, id
  if all_hash_vertices[id][key] != nil
    all_hash_vertices[id][key].each do |value|
      if exist value || value == nil
        next
      end
      $trajectories[$index_tra] << value;
      p $trajectories[$index_tra]
      create_trajectories_recursion all_hash_vertices, value, id

      $index_tra+=1
    end
  end

end

def create_trajectories_from_start_point all_hash_vertices, start_points, id
  p "Create trajectories -------------------------------"
  #trajectories = Array2D.new
  p start_points
  start_points.each do |start_point| #[123, 1342, 42]
    p start_point
    $trajectories[$index_tra] << start_point
    all_hash_vertices[id][start_point].each do |value|
      if exist value || value == nil
        next
      end
      $trajectories[$index_tra] << value;
      p "Base-> #{$trajectories[$index_tra]}"
      create_trajectories_recursion all_hash_vertices, value, id
      # p "VALUE"
      # p value
      # break
      $index_tra+=1
    end
  end
  p start_points
end

def create_trajectories all_hash_vertices, id
  p "Create trajectories -------------------------------"
    # all_hash_vertices[id].each do |key|
    #   $trajectories[$index_tra] << key
    #   all_hash_vertices[id][key].each do |value|
    #     $trajectories[$index_tra] << value
    #     create_trajectories_recursion all_hash_vertices, value, id
    #     # p "VALUE"
    #     # p value
    #     # break
    #     $index_tra+=1
    #   end
    # end
    all_hash_vertices[id].each do |key, value|
      $trajectories[$index_tra] << key
      value.each do |v|
        $trajectories[$index_tra] << v
        create_trajectories_recursion all_hash_vertices, value, id
        $index_tra+=1
      end
    end


end


def print_all_hash_vertices all_hash_vertices, id
  all_hash_vertices[id].each do |key, value|
    print "#{key} -> "
    print value
    puts "\n"
  end
end

def send_trajectory trajectory, sector
  uri = URI("#{ HOST_URL }/api/sector/#{ sector }/company/#{ COMPANY_NAME }/trajectory")
  Net::HTTP.post_form(uri, 'trajectory' => trajectory)
end

all_objects = Array2D.new
all_roots = Array2D.new
all_hash_vertices = Array.new { Hash.new }
new_all_hash_vertices = Array2D.new { Hash.new }

id = 9

  # Взима всички edges от сървъра
  all_objects[id] = get_objects id
  #p all_objects[id]
  # Взима всички roots от сървъра
  all_roots[id] = get_roots id
  #p all_roots[id]
  # Съставя масив от всички хашове в който, като key е vertex,
  # а като value е масив от vertices, към които гореспоменатия key сочи.
  all_hash_vertices[id] = vertices_map all_objects[id]



  # Служи за принтиране на всички хашове в сектор.
  # print_all_hash_vertices all_hash_vertices, id


# Връща 10 масива, като всеки има в себе си масив от хашове
# без roots в него.
new_all_hash_vertices = extirpate_roots all_hash_vertices, all_roots, id

start_points = find_start_points all_hash_vertices, id
create_trajectories all_hash_vertices, id

#create_trajectories_from_start_point all_hash_vertices, start_points, id

p "///////////////////////////////"
p $trajectories
# create_trajectories all_hash_vertices, start_points, id
  # Служи за принтиране на всички хашове в сектор.
  #print_all_hash_vertices new_all_hash_vertices, id


# Трябва да върща траекториите подходящи за пращане към сървъра.
# Трябва да прочетеш условието на заданието!
# create_trajectory new_all_hash_vertices, id, trajectory_array

# Това не ти трябва за направата на траекторията!
p "///////////////////////////////"
#p new_all_hash_vertices[id]
  # new_all_hash_vertices[id].each do |key, value|
  #   value.each do |v|
  #     send_trajectory "#{key} #{v}", id
  #   end
  # end
