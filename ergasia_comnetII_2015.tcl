#Create a simulator object
set ns [new Simulator]

#Open the trace file
set tr [open out.trace w]
$ns trace-all $tr

#Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

set flows_number #

set start_time 0 
set finish_time #
set bw_src #
set delay_src #
set bw_backbone #
set delay_backbone #
set bw_dst #
set delay_dst #
set buffer_size #
set queue #


##### Baseline Configuration  - Begins here #####

Queue/RED set thresh_ 0
Queue/RED set maxthresh_ 0
Queue/RED set q_weight_ -1
Queue/RED set wait_ false
Queue/RED set linterm_ 10
Queue/RED set gentle_ false
Queue/RED set cautious_ 0
Queue/RED set adaptive_ 0
Queue/RED set idle_pktsize_ 100

#Don't activate more than one of the following methods simultaneously
Queue/RED set drop_tail_ false
Queue/RED set drop_front_ false
Queue/RED set drop_rand_ true

##### Baseline Configuration  - Ends here #####

#You are not allowed to change these values
Queue/RED set mean_pktsize_ 1000
Queue/RED set setbit_ false; #ECN is not supported by our system


#Define a 'finish' procedure
proc finish {} {
	global ns f tr nf flows_number
	$ns flush-trace
	#Close the NAM trace file
	close $nf
	close $tr
	close $f
	#Execute NAM on the trace file
	#exec nam out.nam &
	#Display results and exit
	get_results
	exit 0
}

#Create secondary nodes and target node
set n0 [$ns node]
set n1 [$ns node]

#Create source & sink nodes (flows)
for {set i 0} {$i < $flows_number} {incr i} {
	set sender($i) [$ns node]
	set receiver($i) [$ns node]
	$ns duplex-link $sender($i) $n0 $bw_src $delay_src DropTail
	$ns duplex-link $receiver($i) $n1 $bw_dst $delay_dst DropTail
	$ns queue-limit $sender($i) $n0 500; # don't change this value 
	$ns queue-limit $receiver($i) $n1 500; #don't change this value
	set tcp_agent($i) [new Agent/TCP/Newreno]
	set tcp_sink($i) [new Agent/TCPSink]
	$ns attach-agent $sender($i) $tcp_agent($i)
	$ns attach-agent $receiver($i) $tcp_sink($i)
	$ns connect $tcp_agent($i) $tcp_sink($i)
	$tcp_agent($i) set window_ 500; #don't change this value
	set ftp_app($i) [new Application/FTP]
	$ftp_app($i) attach-agent $tcp_agent($i)

	$ns at $start_time "$ftp_app($i) start"
	$ns at $finish_time "$ftp_app($i) stop"
}
 

#Create links between the n0-n1 nodes
$ns duplex-link $n0 $n1 $bw_backbone $delay_backbone $queue 

#Set Queue Size of link (n0-n1) to a constant value
$ns queue-limit $n0 $n1 $buffer_size

#Schedule events for FTP agents
#Call the finish procedure after 10cd /ns seconds of simulation time
$ns at $finish_time "finish"

proc get_results {} {
 
}

#Run the simulation
$ns run
