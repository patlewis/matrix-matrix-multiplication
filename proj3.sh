#!/bin/bash

#=========================Part A====================================#
mkdir -p results
n1=512
n2=1024
n3=4096

declare -a cores=(1 2 4 8 16 32)
declare -a sizes=(512 724 1024 1448 2048 2912)

#compile and then check for errors
#mpicc -o part_a -g -Wall -Werror ring_matrix_part_a.c
#if [ $? -ne 0 ]; then
#    return
#fi

#set up data files
printf "np time speedup" > results/n1_results_part_a
printf "np time speedup" > results/n2_results_part_a
printf "np time speedup" > results/n3_results_part_a
printf "np size time flops mflops/s" > results/isogranularity_part_a

# Do data run for speedup numbers
printf "Collecting data\n"
for n in $n1 $n2 $n3
do
    printf "%d\n" $n #for debug
    for p in "${cores[@]}"   #different processor numbers
    do
        printf "%d" $p #for debug
        for i in {1..100}       #run multiple times for good data
        do
            mpirun -np $p -hostfile nodes ./part_a $n >> tmp
            printf "." #for debug
        done
        #if this is the first one, remember the time for speedup calculations
        if [ "$p" -eq 1 ]; then
            spdf=$(awk '{sum+=$1} END {avg=sum/NR; print avg}' tmp)
        fi
        #do speedup calculations, send to correct files
        if [ "$n" -eq "$n1" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,avg/fac}' tmp >> results/n1_results_part_a 
        elif [ "$n" -eq "$n2" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,avg/fac}' tmp >> results/n2_results_part_a 
        elif [ "$n" -eq "$n3" ]; then
            awk -v fac="$spdf" -v procs="$p" '{sum+=$1} END {avg=sum/NR; print procs,avg,avg/fac}' tmp >> results/n3_results_part_a 
        fi
        #remove temp file for the next iteration
        rm -f tmp
    done
done

# Do data runs for isogranularity
printf "Collecting data for isogranularity\n"
numcores=${#cores[@]}
for k in {0..5}
do
    printf "%d cores" ${cores[$k]}
    for i in {1..100}
    do
	printf "."
        mpirun -np ${cores[$k]} -hostfile nodes ./part_a ${sizes[$k]} >> tmp
    done
    #do math and come up with FLOPS numbers
    awk -v procs="${cores[$k]}" -v size="${sizes[$k]}" '{sum+=$1} END {avg=sum/NR; flops=2*size^3; print procs,size,avg,flops,(flops/1000)/avg}' tmp >> results/isogranularity_part_a
   rm -f tmp
done 

printf "Making plots\n"
# Make a plot of speedup
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "speedup_plot_part_a.png"
set title "Speedup vs. Number of Processes"
set xlabel "Processes (p)"
set ylabel "Speedup Factor"
set autoscale
plot "results/n1_results_part_a" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 5, "results/n2_results_part_a" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 5, "results/n3_results_part_a" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf, 30" enhanced color
set output "speedup_plot_part_a.eps"
plot "results/n1_results_part_a" using 1:3 title "n = ${n1}" with linespoints pointtype 6 lw 10
plot "results/n2_results_part_a" using 1:3 title "n = ${n2}" with linespoints pointtype 6 lw 10
plot "results/n3_results_part_a" using 1:3 title "n = ${n3}" with linespoints pointtype 6 lw 10
__EOF

# Make the isogranularity plot
cat << __EOF | gnuplot
set term png size 800,600 font "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
set output "isogranularity_part_a.png"
set title "Isogranularity"
set xlabel "Number of Processes (p)"
set ylabel "Millions of Floating-Point Operations per Second (mFLOPS/s)"
set autoscale
plot "results/isogranularity_part_a" using 1:5 title "iso" with linespoints pointtype 6 lw 5

set term postscript eps size 8,6 font "/usr/share/fonts/dejavu/DejavuSans-Bold.ttf, 30" enhanced color
set output "isogranularity_part_a.eps"
plot "results/isogranularity_part_a" using 1:5 title "iso" with linespoints pointtype 6 lw 10
__EOF

mv *.png *.eps resutls/

#=========================Part B====================================#
#=========================Part C====================================#
