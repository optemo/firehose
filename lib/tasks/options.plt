set size 1.0, 1.0;
set xlabel 'orders factor'; 
set ylabel 'Sales'; 
set yrange [0:50]
set xrange[0:1]
plot '../../tmp/Daily_Data/camera_bestbuy_Cumullative_Data.txt' using 11:4 with points lt 3 pt 2 title 'camera bestbuy Cumullative Data'