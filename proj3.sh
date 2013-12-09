#!/bin/bash

#=========================Part A====================================#
n1=512
n2=1024
n3=4096

declare -a cores=(1 2 4 8 16 32)
declare -a sizes=(512 724 1024 1448 2048 2912)

#compile and then check for errors
mpicc -o part_a -g -Wall -Werror ring_matrix_part_a.c
if [ $? -ne 0 ]; then
    return
fi

#set up data files
printf "np time speedup" > n1_results_part_a
printf "np time speedup" > n2_results_part_a
printf "np time speedup" > n3_results_part_a
printf "np size time flops mflops/s" > isogranularity_part_a

# Do data run for speedup numbers
for n in n1 n2 n3
do
    for p in cores   #different processor numbers
    do
        for i in {1..100}       #run multiple times for good data
        do
            mpirun -np $p -hostfile nodes ./part_a $n >> tmp
        done
        #if this is the first one, remember the time for speedup calculations
        if [ $p -eq 1 ]; then
            spdf=$(awk '{sum+=$1} END {avg=sum/NR; print avg}' tmp)
        fi
        #do speedup calculations, send to correct files
        if [ $n -eq $n1 ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,avg/fac}' tmp >> n1_results_part_a 
        elif [ $n -eq $n2 ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,avg/fac}' tmp >> n2_results_part_a 
        elif [ $n -eq $n3 ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,avg/fac}' tmp >> n3_results_part_a 
        fi
        #remove temp file for the next iteration
        rm -f tmp
    done
done

# Do data runs for isogranularity
for k in {1..${#cores}}
do
    for i in {1..100}
    do
        mpirun -np ${cores[$k]} -hostfile nodes ./part_a ${sizes[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
   awk -v procs="${cores[$k]}" -v size="${sizes[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000)/avg}' tmp >> isogranularity_part_a
   rm -f tmp
done 

# Make a plot of speedup
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "speedup_plot_part_a.png"
set title "Speedup vs. Number of Processes"
set xlabel "Processes (p)"
set ylabel "Speedup Factor"
set autoscale
plot "n1_results_part_a" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 5
plot "n2_results_part_a" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 5
plot "n3_results_part_a" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 5

set term postscript eps size 8.6 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf, 30" enhanced color
set output "speedup_plot_part_a.eps"
plot "n1_results_part_a" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 10
plot "n2_results_part_a" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 10
plot "n3_results_part_a" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 10
__EOF

# Make the isogranularity plot
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "isogranularity_part_a.png"
set title "Isogranularity"
set xlabel "Number of Processes (p)"
set ylabel "Millions of Floating-Point Operations per Second (mFLOPS/s):
set autoscale
plot "isogranularity_part_a" using 1:4 with linespoints pointtype 6 lw 5

set term postscript eps size 8.6 font "/usr/share/fonts/dejavu/DejavuSans-Bold.ttf, 30" enhanced color
set output "isogranularity_part_a.eps"
plot "isogranularity_part_a" using 1:4 with linespoints pointtype 6 lw 10
__EOF



#=========================Part B====================================#
#=========================Part C====================================#
