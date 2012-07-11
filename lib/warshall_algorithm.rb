class Warshall
 def initialize(adjacencyMatrix)
  @adjacencyMatrix=adjacencyMatrix
 end
 
 def getPathMatrix
  unless @adjacencyMatrix.empty?
    numNodes=@adjacencyMatrix[0].length
    pathMatrix=Array.new(@adjacencyMatrix)
    for k in 0...numNodes
     for i in 0...numNodes
      #Optimization: if no path from i to k, no need to test k to j
      if pathMatrix[i][k]==1 then 
       for j in 0...numNodes
        if pathMatrix[k][j]==1 then
         pathMatrix[i][j]=1
        end
       end
      end
     end
    end
  else
    pathMatrix = Array.new
  end
  return pathMatrix
 end

 def showPathMatrix
  puts "adjacency"
  @adjacencyMatrix.each{|c| print c,"\n"}
  puts "path"
  getPathMatrix.each{|c| print c,"\n"}
 end 

end
