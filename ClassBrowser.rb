
# Dummy test class. Used for testing the c, and v commands
# this class can be reached using the class browser, i mostly used this to test the
# functionality of the v command
class DummyTest
  def initialize
    @test = 1
    @test2 = 2
  end
end

# the main driver class, make an object of this and call inputLoop to start off
class ClassBrowser
  #Class Variables

  # used to hold an object of the current class. Changes constantly throughout
  # the program when visiting the different classes
  @@currClass = ClassBrowser.new
  # list of subclasses. It changes whenever a new class is visited. Then can
  # be accessed again later for the functionality of the u command
  @@listSubclasses = []
  # used for the b command, holds at most 3 names of classes to be moved back to
  @@previousClasses = []
  # after popping something out from previous, it gets stored in forward in case this is called again
  # later.
  @@forwardClasses = []
  # flag variable to see if b was used last, used in the f functionality, resolveF function
  @@bLastUsed = false
  # init function, just a little print statement welcoming the user to the program
  # as well as giving a default value to the input
  def initialize
    puts 'Welcome to the class browser program.'
    @input = ''

  end

  # merge sort algorithm
  # this function does the actual sorting of the two sub arrays created by mergeSort function
  def mergeHelper(l,r)
    #puts 'inside mergeHelper'
    sortedStorage = []
    # while the arrays still have elements in them, execute this loop
    while !l.empty? && !r.empty?
      if(l[0] < r[0])
        sortedStorage.push(l.shift)
      else
        sortedStorage.push(r.shift)
      end
    end
    # now that we merged the arrays, concat and return
    sortedStorage.concat(l,r)
    return sortedStorage
  end

  # this is the function to call when you want to merge sort, driver function splits up the array into
  # left and right halves and sends them into the mergeHelper function
  def mergeSort(arr)
    # if we have an array that only contains one element or nothing, theres nothing to sort then
    if(arr == nil)
      return []
    end
    if(arr.length <= 1)
      return arr # simply just return what we got
    else
      # else we have an array that is sortable, split up the arrays down the midpoint and send them into the driver function
      midpoint = arr.length/2
      half1 = mergeSort(arr.slice(0...midpoint))
      half2 = mergeSort(arr.slice(midpoint...arr.length))
      mergeHelper(half1,half2)
    end

  end

  #helper function used in printing the class information. Basically enumerates the list so that
  # the user can know what index a method, subclass can be reached at.
  def printListEnumerated(arr)
    i = 0
    while i < arr.length
      puts '  ' + i.to_s + '  ' + arr[i].to_s
      i += 1
    end
    if(arr.length == 0)
      puts '  List is empty.'
    end

  end

  # used to adjust the sive of the previousclasses array, i want the size of this to be fixed
  # at 3, so it gets called if the function ever goes over 3.
  def fixPrevArr
    temp1 = @@previousClasses[1];
    temp2 = @@previousClasses[2];
    @@previousClasses[0] = temp1;
    @@previousClasses[1] = temp2;
    @@previousClasses[2] = @@previousClasses[3]
    @@previousClasses.pop
  end

  #when initially getting a list of subclasses, i want to convert them into strings
  # so that they can be compared and sorted in the mergeSort function. Also does some filtering
  # to only allow for direct subclasses
  def convertObjectsArrToStringArr(arr)
    i = 0
    stringArr = []
    while i < arr.length
      holder = arr[i].to_s
      if(holder != "")
        if(holder[0] != "#")
          if(!holder.include? "::")
             stringArr.append(holder)
          end
        end
      end
        #p holder
      # puts stringArr[i]
      i += 1
    end
    return stringArr
  end

  # helper function. Simply displays the list of commands and what each command does.
  # I added in a command z to redisplay the class information in case it gets lost in the
  # sea of text from the command line and you dont wanna have to scroll up.
  def printCommands
    puts 's: Display the superclass information.'
    puts 'u: (n) n-th subclass'
    puts 'v: list of instance variables'
    puts 'c: (string) Class name input'
    puts 'b: return to the previous class'
    puts 'f: return forward, after b is used'
    puts 'z: repeat information'
    puts 'q: quit'
  end

  # this is the 4 pieces of information per the project writeup. This gets called
  # whenever the current class changes, and displays the information the new class
  # this is also where the subclasses and methods arrays are sorted.
  def defaultInfo
    temp = @@currClass
    # set 1
    puts '1.Name of current class: ' + temp.class.name
    # set 2
    puts '2.Name of superclass: ' + temp.class.superclass.to_s

    # set 3
    puts '3.List of subclasses'
    subclasses = (ObjectSpace.each_object(Class).select { | kl | kl < temp.class})
    subclasses2 = convertObjectsArrToStringArr(subclasses)

    subclasses2 = mergeSort(subclasses2)
    if(subclasses2 == nil)
      subclasses2 = []
    end
    printListEnumerated(subclasses2)
    @@listSubclasses = subclasses2

    # set 4
    puts '4. List of methods'
    methods = temp.class.instance_methods(false)
    methods2 = convertObjectsArrToStringArr(methods)
    methods2 = mergeSort(methods2)
    if(methods2 == nil)
      methods2 = []
    end

    printListEnumerated(methods2)
  end

  # called whenever the s command is detected. Returns to the superclass, if we are already
  # at the root class ie object, we do not do anything, and no changes are made. If we are not, then we
  # check if we can make a new object of the super class, and if we can, we update the current class.
  def resolveS
    if(@@currClass.class.name == "Object")
      puts 'Cannot move to superclass. Already in root class'
    else
      temp =  @@currClass.class.superclass.to_s
      temp2 = Kernel.const_get(temp).new
      @@previousClasses.append(@@currClass.class.name)
      if(@@previousClasses.length == 4)
        fixPrevArr
      end
      @@currClass = temp2

      defaultInfo
    end
    @@bLastUsed = false
    @@forwardClasses = []
  end

  # same idea as s, but instead of returning to the superclass, we are picking from the array of subclasses
  # that inherit from our current class. does some integer parsing to make sure that we have good input, then checks
  # if the index we want to go to is within the boundaries of the array of the subclasses. After all of that, we check
  # if we can make an object of the new subclass, that does not require any parameters. If we cannot create an object,
  # or if our input is no good, the command does not execute.
  def resolveU(input)
    #first up some integer parsing
    if(input.length < 3)
      puts 'Cannot resolve command. Returning to menu.'
    else
      temp = input[2..input.length-1]
      temp2 = Integer(temp)

      if(temp2.to_s == temp)

        #puts temp2
        # now we know the input is good, lets check if its in bounds of the list of classes
        if (temp2 >= 0 && temp2 <= @@listSubclasses.length)
          newClass = @@listSubclasses[temp2]
          begin
            newClassObj = Kernel.const_get(newClass).new
            @@previousClasses.append(@@currClass.class.name)
            if(@@previousClasses.length == 4)
              fixPrevArr
            end
            @@currClass = newClassObj

            defaultInfo
          rescue
            puts 'Could not create object as it required parameters to be made. Returning.'
          end

        else
          puts 'Index was out of bounds. Try again.'
        end
      else
        puts 'No number detected.'
      end

      #puts temp
    end
    #puts input
    @@bLastUsed = false
    @@forwardClasses = []
  end

  #simple function, just prints out a list of instance variables, if its empty, then it just prints [].
  # one of the easier functions to have implemented.
  def resolveV
    puts 'printing a list of instance variables:'

    puts @@currClass.instance_variables.to_s
    @@bLastUsed = false
    @@forwardClasses = []
  end

  #takes in another arguement of a string of the classname we want to go to. So does some string manipulation to get the
  # string of the class that we want to go to and then checks if we can visit that class. if not an error message will
  # display
  def resolveC(input)
    if(input.length < 3)
      puts 'Cannot resolve command. Returning to menu.'
    else
      newClass = input[2..input.length-1]
      begin
        newClassObj = Kernel.const_get(newClass).new
        @@previousClasses.append(@@currClass.class.name)
        if(@@previousClasses.length == 4)
          fixPrevArr
        end
        @@currClass = newClassObj

        defaultInfo
      rescue
        puts 'Could not create object as class doesnt exist, or required parameters. returning.'
      end
    end
    @@bLastUsed = false
    @@forwardClasses = []
  end

  #as we progress through classes, we keep track of the classes that we visited. we restrict the size of the classes
  # that we remember to 3. Then we can go back and revisit some of these classes using this command.
  def resolveB
    if(@@previousClasses.empty?)
      puts "No more previous classes available. Please visit more classes to move back."
    else
      begin
        @@forwardClasses.append(@@currClass.class.name)
        newClass = @@previousClasses[@@previousClasses.length - 1]
        newClassObj = Kernel.const_get(newClass).new
        @@currClass = newClassObj
        @@previousClasses.pop
        defaultInfo
        puts 'List of previous classes: ' + @@previousClasses.to_s
      rescue
        puts 'Could not create object as class doesnt exist, or required parameters. returning.'
      end
    end
    @@bLastUsed = true
  end
  # can only be used after b is called and no other commands are used other than b or f. Undos the actions of the
  # b command
  def resolveF
    if(@@bLastUsed == false)
      puts "b was not used last. returning."
    elsif(@@forwardClasses.empty?)
      puts "No more forward classes available. Please visit use command b to move back."
    else
      @@previousClasses.append(@@currClass.class.name)
      newClass = @@forwardClasses[@@forwardClasses.length - 1]
      newClassObj = Kernel.const_get(newClass).new
      @@currClass = newClassObj
      @@forwardClasses.pop
      defaultInfo
      puts 'List of forward classes: ' + @@forwardClasses.to_s
    end
  end

  # the input loop, prints out the initial class info, commands and loops until we quit out the program.
  def inputLoop
    defaultInfo
    printCommands
    puts 'Your input:'
    input = gets.chomp
    while input != 'q'

      if input == 's'
        # puts 's selected.'
        resolveS
      elsif input[0] == 'u'
        resolveU(input)

      elsif input == 'v'
        resolveV

      elsif input[0] == 'c'
        #puts 'c selected.'
        resolveC(input)


      elsif input == 'b'
        #puts 'b selected.'
        resolveB
      elsif input == 'f'
        #puts 'f selected.'
        resolveF

      elsif input == 'q'
        #puts 'q selected. exiting program.'
        exit
      elsif input == 'z'
        defaultInfo
      else
        puts 'input unknown. try again.'
      end
      printCommands
      puts 'Your input:'
      input = gets.chomp
    end

  end

end


#to get started, make a classBrowser object and call input loop.
cb = ClassBrowser.new
cb.inputLoop

