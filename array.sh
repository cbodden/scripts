!/bin/bash
myarr=('foo' 'bar' 'baz')
echo ${myarr[*]}
echo ${myarr[@]}
echo "${myarr[*]}"
echo "${myarr[@]}" # looks just like the previous line's output
for i in "${myarr[*]}"; do # echoes one line containing all three elements
       echo $i
   done
   for i in "${myarr[@]}"; do  # echoes one line for each element of the array.
          echo $i
      done

echo element 0 "${myarr[0]}"
echo element 1 "${myarr[1]}"
echo element 2 "${myarr[2]}"
