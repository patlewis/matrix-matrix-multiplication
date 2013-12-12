#!/bin/bash

#=========================Part A====================================#
mkdir -p results
n0=128
n1=256
n2=512
n3=1024

declare -a cores=(1 2 4 8 16 24 32)
declare -a sizes1=(512 724 1024 1448 2048 2496 2912)
declare -a sizes2=(128 180 256 360 512 624 736)
declare -a sizes3=(64 90 128 184 256 312 352)

#compile and then check for errors
mpicc -o part_a -Wall -Werror ring_matrix_part_a.c
if [ $? -ne 0 ]; then
    return
fi

#set up data files
printf "np time speedup\n" > results/n0_results_part_a
printf "np time speedup\n" > results/n1_results_part_a
printf "np time speedup\n" > results/n2_results_part_a
printf "np time speedup\n" > results/n3_results_part_a
printf "np size time flops mflops/s\n" > results/isogranularity_part_a_1
printf "np size time flops mflops/s\n" > results/isogranularity_part_a_2
printf "np size time flops mflops/s\n" > results/isogranularity_part_a_3

# Do data run for speedup numbers
printf "Collecting data\n"
for n in $n0 $n1 $n2 $n3
do
    printf "\n%d--" $n #for debug
    for p in "${cores[@]}"   #different processor numbers
    do
        printf "\n%d" $p #for debug
        for i in {1..10}       #run multiple times for good data
        do
            mpirun -np $p -hostfile nodes ./part_a $n >> tmp
            printf "." #for debug
        done
        #if this is the first one, remember the time for speedup calculations
        if [ "$p" -eq 1 ]; then
            spdf=$(awk '{sum+=$1} END {avg=sum/NR; print avg}' tmp)
        fi
        #do speedup calculations, send to correct files
        if [ "$n" -eq "$n0" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n0_results_part_a 
        elif [ "$n" -eq "$n1" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n1_results_part_a 
        elif [ "$n" -eq "$n2" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n2_results_part_a 
        elif [ "$n" -eq "$n3" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n3_results_part_a 
        fi
        #remove temp file for the next iteration
        rm -f tmp
    done
done

# Do data runs for isogranularity
printf "\nCollecting data for isogranularity\n"
printf "First set of sizes\n"
for k in {0..6}
do
    printf "\n%d cores" ${cores[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_a ${sizes1[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes1[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_a_1
   rm -f tmp
done 
printf "Second set of sizes\n"
for k in {0..6}
do
    printf "\n%d cores" ${cores[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_a ${sizes2[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes2[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_a_2
   rm -f tmp
done 
printf "Third set of sizes\n"
for k in {0..6}
do
    printf "\n%d cores" ${cores[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_a ${sizes3[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes3[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_a_3
   rm -f tmp
done 

printf "\n\nMaking plots\n"
# Make a plot of speedup
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "speedup_plot_part_a.png"
set title "Speedup vs. Number of Processes"
set xlabel "Processes (p)"
set ylabel "Speedup Factor"
set autoscale
set key left top
set grid xtics ytics
plot "results/n0_results_part_a" using 1:3 title "n = ${n0}" with linespoints pointtype 6 lw 5, "results/n1_results_part_a" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 5, "results/n2_results_part_a" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 5, "results/n3_results_part_a" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf, 30" enhanced color
set output "speedup_plot_part_a.eps"
plot "results/n0_results_part_a" using 1:3 title "n = ${n0}" with linespoints pointtype 6 lw 5, "results/n1_results_part_a" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 10, "results/n2_results_part_a" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 10, "results/n3_results_part_a" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 10
__EOF

# Make the isogranularity plot
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "isogranularity_part_a.png"
set title "Isogranularity"
set xlabel "Number of Processes (p)"
set ylabel "Millions of Floating-Point Operations per Second (MFLOPS/s)"
set autoscale
set key left top
set grid xtics ytics
plot "results/isogranularity_part_a_1" using 1:5 title "sizes 1" with linespoints pointtype 6 lw 5, "results/isogranularity_part_a_2" using 1:5 title "sizes 2" with linespoints pointtype 6 lw 5, "results/isogranularity_part_a_3" using 1:5 title "sizes 3" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejavuSans-Bold.ttf, 30" enhanced color
set output "isogranularity_part_a.eps"
plot "results/isogranularity_part_a_1" using 1:5 title "sizes 1" with linespoints pointtype 6 lw 10, "results/isogranularity_part_a_2" using 1:5 title "sizes 2" with linespoints pointtype 6 lw 10, "results/isogranularity_part_a_3" using 1:5 title "sizes 3" with linespoints pointtype 6 lw 10
__EOF

mv *.png *.eps results/

#=========================Part B====================================#
mkdir -p results
printf "\n\n Part B\n\n"
n0=128
n1=256
n2=512
n3=1024

declare -a nodes=(1 1 1 1 2 3 4)
declare -a threads=(1 2 4 8 8 8 8)
declare -a sizes1=(512 724 1024 1448 1448 1448 1448)
declare -a sizes2=(128 180 256 360 360 360 360)
declare -a sizes3=(64 90 128 184 184 184 184)

#compile and then check for errors
mpicc -o part_b -Wall -Werror -fopenmp ring_matrix_part_b.c
if [ $? -ne 0 ]; then
    exit
fi

#set up data files
printf "np time speedup\n" > results/n0_results_part_b
printf "np time speedup\n" > results/n1_results_part_b
printf "np time speedup\n" > results/n2_results_part_b
printf "np time speedup\n" > results/n3_results_part_b
printf "np size time flops mflops/s\n" > results/isogranularity_part_b_1
printf "np size time flops mflops/s\n" > results/isogranularity_part_b_2
printf "np size time flops mflops/s\n" > results/isogranularity_part_b_3

# Do data run for speedup numbers
printf "Collecting data\n"
for n in $n0 $n1 $n2 $n3
do
    printf "\n%d--" $n #for debug
    for p in {0..6}   #different processor numbers
    do
        printf "\n%d node %d threads" ${nodes[$p]} ${threads[$p]} #for debug
        for i in {1..10}       #run multiple times for good data
        do
            mpirun -np ${nodes[$p]} -hostfile nodes ./part_b $n ${threads[$p]} >> tmp
            printf "." #for debug
        done
        #if this is the first one, remember the time for speedup calculations
        if [ "$p" -eq 0 ]; then
            spdf=$(awk '{sum+=$1} END {avg=sum/NR; print avg}' tmp)
        fi
        #do speedup calculations, send to correct files
        if [ "$n" -eq "$n0" ]; then
            awk -v fac="$spdf" -v procs="${nodes[$p]}" -v trds="${threads[$p]}" '{sum+=$1} END {avg=sum/NR; print procs*trds,avg,fac/avg}' tmp >> results/n0_results_part_b
        elif [ "$n" -eq "$n1" ]; then
            awk -v fac="$spdf" -v procs="${nodes[$p]}" -v trds="${threads[$p]}" '{sum+=$1} END {avg=sum/NR; print procs*trds,avg,fac/avg}' tmp >> results/n1_results_part_b
        elif [ "$n" -eq "$n2" ]; then
            awk -v fac="$spdf" -v procs="${nodes[$p]}" -v trds="${threads[$p]}" '{sum+=$1} END {avg=sum/NR; print procs*trds,avg,fac/avg}' tmp >> results/n2_results_part_b
        elif [ "$n" -eq "$n3" ]; then
            awk -v fac="$spdf" -v procs="${nodes[$p]}" -v trds="${threads[$p]}" '{sum+=$1} END {avg=sum/NR; print procs*trds,avg,fac/avg}' tmp >> results/n3_results_part_b
        fi
        #remove temp file for the next iteration
        rm -f tmp
    done
done

# Do data runs for isogranularity
printf "\nCollecting data for isogranularity\n"
printf "Size set 1"
for k in {0..6}
do
    printf "\n%d cores" ${nodes[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${nodes[$k]} -hostfile nodes ./part_b ${sizes1[$k]} ${threads[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${nodes[$k]}" -v size="${sizes1[$k]}" -v trds="${threads[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs*trds,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_b_1
   rm -f tmp
done 
printf "Size set 1"
for k in {0..6}
do
    printf "\n%d cores" ${nodes[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${nodes[$k]} -hostfile nodes ./part_b ${sizes2[$k]} ${threads[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${nodes[$k]}" -v size="${sizes2[$k]}" -v trds="${threads[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs*trds,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_b_2
   rm -f tmp
done 
printf "Size set 1"
for k in {0..6}
do
    printf "\n%d cores" ${nodes[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${nodes[$k]} -hostfile nodes ./part_b ${sizes3[$k]} ${threads[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${nodes[$k]}" -v size="${sizes3[$k]}" -v trds="${threads[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs*trds,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_b_3
   rm -f tmp
done 

printf "\n\nMaking plots\n"
# Make a plot of speedup
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "speedup_plot_part_b.png"
set title "Speedup vs. Number of Processes"
set xlabel "Processes (p)"
set ylabel "Speedup Factor"
set autoscale
set key left top
set grid xtics ytics
plot "results/n0_results_part_b" using 1:3 title "n = ${n0}" with linespoints pointtype 6 lw 5, "results/n1_results_part_b" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 5, "results/n2_results_part_b" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 5, "results/n3_results_part_b" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf, 30" enhanced color
set output "speedup_plot_part_b.eps"
plot "results/n0_results_part_b" using 1:3 title "n = ${n0}" with linespoints pointtype 6 lw 5, "results/n1_results_part_b" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 10, "results/n2_results_part_b" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 10, "results/n3_results_part_b" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 10
__EOF

# Make the isogranularity plot
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "isogranularity_part_b.png"
set title "Isogranularity"
set xlabel "Number of Processes (p)"
set ylabel "Millions of Floating-Point Operations per Second (MFLOPS/s)"
set autoscale
set key left top
set grid xtics ytics
plot "results/isogranularity_part_b_1" using 1:5 title "size set 1" with linespoints pointtype 6 lw 5, "results/isogranularity_part_b_2" using 1:5 title "size set 1" with linespoints pointtype 6 lw 5, "results/isogranularity_part_b_3" using 1:5 title "size set 1" with linespoints pointtype 6 lw 5



set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejavuSans-Bold.ttf, 30" enhanced color
set output "isogranularity_part_b.eps"
plot "results/isogranularity_part_b" using 1:5 title "iso" with linespoints pointtype 6 lw 10
__EOF

mv *.png *.eps results/
#=========================Part C====================================#
mkdir -p results
printf "\n\nPart C\n\n"
n0=128
n1=256
n2=512
n3=1024

declare -a cores=(1 2 4 8 16 24 32)
declare -a sizes1=(512 724 1024 1448 2048 2496 2912)
declare -a sizes2=(128 180 256 360 512 624 736)
declare -a sizes3=(64 90 128 184 256 312 352)

#compile and then check for errors
mpicc -o part_c ring_matrix_part_c.c
if [ $? -ne 0 ]; then
    return
fi

#set up data files
printf "np time speedup\n" > results/n0_results_part_c
printf "np time speedup\n" > results/n1_results_part_c
printf "np time speedup\n" > results/n2_results_part_c
printf "np time speedup\n" > results/n3_results_part_c
printf "np size time flops mflops/s\n" > results/isogranularity_part_c_1
printf "np size time flops mflops/s\n" > results/isogranularity_part_c_2
printf "np size time flops mflops/s\n" > results/isogranularity_part_c_3

# Do data run for speedup numbers
printf "Collecting data\n"
for n in $n0 $n1 $n2 $n3
do
    printf "\n%d--" $n #for debug
    for p in "${cores[@]}"   #different processor numbers
    do
        printf "\n%d" $p #for debug
        for i in {1..10}       #run multiple times for good data
        do
            mpirun -np $p -hostfile nodes ./part_c $n >> tmp
            printf "." #for debug
        done
        #if this is the first one, remember the time for speedup calculations
        if [ "$p" -eq 1 ]; then
            spdf=$(awk '{sum+=$1} END {avg=sum/NR; print avg}' tmp)
        fi
        #do speedup calculations, send to correct files
        if [ "$n" -eq "$n0" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n0_results_part_c 
        elif [ "$n" -eq "$n1" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n1_results_part_c 
        elif [ "$n" -eq "$n2" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n2_results_part_c 
        elif [ "$n" -eq "$n3" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,fac/avg}' tmp >> results/n3_results_part_c 
        fi
        #remove temp file for the next iteration
        rm -f tmp
    done
done

# Do data runs for isogranularity
printf "\nCollecting data for isogranularity\n"
printf "First set of sizes\n"
for k in {0..6}
do
    printf "\n%d cores" ${cores[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_c ${sizes1[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes1[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_c_1
   rm -f tmp
done 
printf "Second set of sizes\n"
for k in {0..6}
do
    printf "\n%d cores" ${cores[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_c ${sizes2[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes2[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_c_2
   rm -f tmp
done 
printf "Third set of sizes\n"
for k in {0..6}
do
    printf "\n%d cores" ${cores[$k]}
    for i in {1..10}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_c ${sizes3[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes3[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000000)/avg}' tmp >> results/isogranularity_part_c_3
   rm -f tmp
done 

printf "\n\nMaking plots\n"
# Make a plot of speedup
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "speedup_plot_part_c.png"
set title "Speedup vs. Number of Processes"
set xlabel "Processes (p)"
set ylabel "Speedup Factor"
set autoscale
set key left top
set grid xtics ytics
plot "results/n0_results_part_c" using 1:3 title "n = ${n0}" with linespoints pointtype 6 lw 5, "results/n1_results_part_c" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 5, "results/n2_results_part_c" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 5, "results/n3_results_part_c" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf, 30" enhanced color
set output "speedup_plot_part_c.eps"
plot "results/n0_results_part_c" using 1:3 title "n = ${n0}" with linespoints pointtype 6 lw 5, "results/n1_results_part_c" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 10, "results/n2_results_part_c" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 10, "results/n3_results_part_c" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 10
__EOF

# Make the isogranularity plot
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "isogranularity_part_c.png"
set title "Isogranularity"
set xlabel "Number of Processes (p)"
set ylabel "Millions of Floating-Point Operations per Second (MFLOPS/s)"
set autoscale
set key left top
set grid xtics ytics
plot "results/isogranularity_part_c_1" using 1:5 title "sizes 1" with linespoints pointtype 6 lw 5, "results/isogranularity_part_c_2" using 1:5 title "sizes 2" with linespoints pointtype 6 lw 5, "results/isogranularity_part_c_3" using 1:5 title "sizes 3" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejavuSans-Bold.ttf, 30" enhanced color
set output "isogranularity_part_c.eps"
plot "results/isogranularity_part_c_1" using 1:5 title "sizes 1" with linespoints pointtype 6 lw 10, "results/isogranularity_part_c_2" using 1:5 title "sizes 2" with linespoints pointtype 6 lw 10, "results/isogranularity_part_c_3" using 1:5 title "sizes 3" with linespoints pointtype 6 lw 10
__EOF

mv *.png *.eps results/
