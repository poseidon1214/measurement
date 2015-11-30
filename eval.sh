#!/user/bin/bash 
set -u

############################
## cat result| sh eval.sh 0.4
############################
##  1. data formating: [predict value]\t[label]
##  2. label in {1:positive, !1: negtive]
##  3. predict value in [0,1]
##  4. split the ctr into [table_size] buckets
############################

rt=$1
awk -F'\t' '
BEGIN{
	##################
	tp=0;
	fp=0;
	tn=0;
	fn=0;
	#################
	clk=0;
	non_clk=0;
	#################
	area=0.0;
	#################
	table_size=100;
	for(i=1;i<=table_size;i++) {
		table[1,i]=0;
		table[2,i]=0;
	}
}
{
	pre=$1;
	label=$2;
	if(label != 1) { 
        label=2;
    }	

	slot=int(pre*table_size);
	table[label,slot]+=1;

    RT='$rt';
	if(pre >= RT && label == 1) {
		tp+=1;	
	}
	else if(pre >= RT && label == 2) {
		fp+=1;
	}
	else if(pre < RT && label == 1) {
		fn += 1;
	}
	else if(pre < RT && label == 2) {
		tn += 1;
	}
}
END{
	for(i=table_size; i>=1; i--) {
		new_non_clk=non_clk+table[2,i];
		new_clk=clk+table[1,i];
		area+=(new_non_clk-non_clk)*(clk+new_clk)/2;
		non_clk=new_non_clk;
		clk=new_clk;
	}
	
	auc=area/(non_clk*clk);
	precision=(tp+fp==0?0:tp/(tp+fp));
	recall=(tp+fn==0?0:tp/(tp+fn));
	total=(tp+fp+tn+fn==0?0:tp+fp+tn+fn);
	
	print "#######################";
	printf("##auc:       %f\n##presicion: %s  %d/%d\n##recal:     %s  %d/%d\n" , auc, precision, tp, tp+fp, recall, tp, tp+fn);
	printf("##pos/total: %f\n", (tp+fn)/total);
	print "#######################";
	printf("####tp:      %d\n", tp);
	printf("####fp:      %d*\n", fp);
	printf("####tn:      %d\n", tn);
	printf("####fn:      %d*\n", fn);
	print "#######################";
	
}'
