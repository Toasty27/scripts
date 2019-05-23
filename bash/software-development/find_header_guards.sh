for file in $(find $1 -type f -name *.h | grep -v guichan)
do

	# This expects there to only be one space between the 'ifndef' and the include guard name
	guardName=$(grep -m 1 "#ifndef" $file | cut -d ' ' -f 2)
	
	if $(grep -A 1 "#ifndef $guardName" $file | grep -B 1 "#define $guardName" > /dev/null) && $(tail -n 1 $file | grep "#endif" > /dev/null)
	then 
		echo $file 

		temp_file="${file}.tmp"

		cp $file $temp_file

		# sed "1,54d" < $file > $temp_file # guichan specific 

		sed -i '' "s/#ifndef\ $guardName/#pragma\ once/" $temp_file
		sed -i '' "s/#define\ $guardName//" $temp_file
		sed -i '' '$d' $temp_file

		# cat guichan_header.txt $temp_file > $file # guichan specific 

		# rm $temp_file

		mv $temp_file $file

		grep -A 1 "#ifndef $guardName" $file | grep -B 1 "#define $guardName"
		tail -n 1 $file | grep -E "#endif"

		echo "====="
		echo
	fi
done
