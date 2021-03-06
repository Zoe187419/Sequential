


#----------ExactBinomial.R-------------------------------------------------------------------

# Version of Sept/2019

# -------------------------------------------------------------------------
# Function produces power and expected signal time for the continuous Sequential Binomial MaxSPRT
# -------------------------------------------------------------------------

Performance.Binomial<- function(N,M=1,cv,z="n",p="n",RR=2,GroupSizes=1,Tailed="upper"){


if(length(GroupSizes)>1){auxgroup<- 1}else{

if(sum(is.numeric(GroupSizes))==0){stop("'GroupSizes' must be a vector of positive integers.",call. =FALSE)}
if(GroupSizes==1){auxgroup<- 2}else{auxgroup<- 1}
                                          }



#################################################################################################################################
######################### HERE IS THE PART FOR CONTINUOUS SEQUENTIAL ANALYSIS (GroupSizes=1) ####################################

if(auxgroup==2){ # OPENS THE PART FOR THE CONTINUOUS CASE


if(Tailed!="upper"){stop("For this version of the Sequential package, Performance.Binomial works only for 'Tailed=upper'.",call. =FALSE)}

MinCases<- M
# N = maximum length of surveillance defined in terms of the total number of adverse events

# MinCases = The minimum number of cases for which a signal is allowed to occur, default=1
# z = matching ratio between exposed and unexposed cases
# p = probability of having a case under the null hypothesis 
# RR is the relative risk

if(p=="n"&z=="n"){stop("Please, at least z or p must be provided.",call. =FALSE)}

if( z!="n"){if(sum(is.numeric(z))!=1){stop("Symbols and texts are not applicable for 'z'. It must be a number greater than zero.",call. =FALSE)}}
if(z<=0){stop("'z' must be a number greater than zero.",call. =FALSE)}

if(p!="n"){
if(is.numeric(p)!=TRUE){stop("Symbols and texts are not applicable for 'p'. It must be a probability measure.",call. =FALSE)}
if(z!="n"&p!="n"){if(p!= 1/(1+z)){stop("Both z and p are specified, but the required relationship that p=1/(1+z) does not hold. Please remove either the definition of z or the definition of p. Only one of them is needed. .",call. =FALSE)}}
if(p<=0|p>=1){stop("p must be a number greater than zero and smaller than 1.",call. =FALSE)}
           }

if(z!="n"){z<- z}else{z<- 1/p-1}


if(is.numeric(N)==FALSE|N<=0){stop("N must be a positive integer.",call. =FALSE)}
if(is.numeric(M)==FALSE|M<=0){stop("M must be a positive integer smaller than or equal to 'N'.",call. =FALSE)}

if(round(N)!=N){stop("N must be a positive integer.",call. =FALSE)}
if(round(M)!=M){stop("M must be a positive integer.",call. =FALSE)}
if(is.numeric(cv)==FALSE){stop("cv must be a positive number.",call. =FALSE)}
if(is.numeric(RR)==FALSE|RR<=0){stop("RR must be a number greater than zero.",call. =FALSE)}


if(MinCases>N){stop("'MinCases' must be an integer smaller than or equal to N.",call. =FALSE)}
if(MinCases<1){stop("'MinCases' must be an integer greater than zero.",call. =FALSE)}
if(MinCases!=round(MinCases)){stop("'MinCases' must be an integer.",call. =FALSE)}


if(N<=0){stop("N must be a positive integer.",call. =FALSE)}
if(N!=round(N)){stop("'N' must be an integer.",call. =FALSE)}

if(RR<1){stop("RR must be greater than or equal to 1.",call. =FALSE)}
if(cv<=0){stop("cv must be a positive number.",call. =FALSE)}

pst<- 1/(1+z)

# Function that calculates the LLR for a given observed (c) and expected (u) number of cases
#-------------------------------------------------------------------------------------------

LLR <- function(cc,n,z){

       if(cc==n){x = n*log(1+z)}else{
         if(z*cc/(n-cc)<=1){x=0}else{
	       x = cc*log(cc/n)+(n-cc)*log((n-cc)/n)-cc*log(1/(z+1))-(n-cc)*log(z/(z+1))
                                    }
                                  } 	
      	x
	}

# Preparing the information of absorbing states
#-------------------------------------------------------------------------------------------
 
absorb = rep(0,N)		# Contains the number of events needed at time mu[i] in order to reject H0
aux<- rep(0,N)

for(i in 1:N){
	while( LLR(absorb[i],i,z)<cv &absorb[i]<i){ 
		absorb[i]=absorb[i]+1               }
             if(LLR(absorb[i],i,z)>=cv){aux[i]<- 1}
             }
if(MinCases>1){
aux[1:(MinCases-1)]<- 0
              }

absorb[aux==0]<- absorb[absorb[aux==0]]+1

for(i in 1:N){if(absorb[i]<MinCases&i>=MinCases){absorb[i]<- MinCases};if(absorb[i]<MinCases&i<MinCases){absorb[i]<- i+1}}


uc<- absorb-1

ps<- RR/(RR+z)

# Auxiliar functions to run the binomial Markov Chain in a fast way:
func_aux2<- function(j,i){ k<- seq(1,uc[i-1]+1); return(sum(p[i-1,k]*dbinom(j-k,1,ps)))} ; func_aux3<- function(i){ k<- seq(1,uc[i-1]+1); return(sum(p[i-1,k]*(1-pbinom(absorb[i]-k,1,ps))))}
func_aux1<- function(i){ j<- matrix(seq(1,absorb[i]),ncol=1) ; return(apply(j,1,func_aux2,i))}

p<- matrix(0,N,N+2)	# p[i,j] is the probability of having j-1 cases at time mu[i]
                   	# p[i,j] is the probability of having j-1 cases at time mu[i]
				# starting probabilities are all set to zero's
                        # i in 1:imax-1 is the rows and j in 1:imax is the column

# Calculating the first row in the p[][] matrix for which there is a chance to reject H0
# --------------------------------------------------------------------------------------

for(s in 1:absorb[1]){ p[1,s]=dbinom(s-1,1,ps)}		# Probability of having s-1 cases at time mu[1]
p[1,absorb[1]+1]=1-pbinom(absorb[1]-1,1,ps)			# probability of rejecting H0 at time mu[1]


if(N>1){
i<- 1
while(i<N){
i<- i+1
       p[i,1:absorb[i]]<- func_aux1(i) # Calculates the standard p[][] cell values
       p[i,absorb[i]+1]<- func_aux3(i) # Calculates the diagonal absorbing states where H0 is rejected                             
                 
          } # end for i	
       }	
# Sums up the probabilities of absorbing states when a signal occurs, to get the power
# ------------------------------------------------------------------------------------------

power=0
time=0

for(i in 1:N){ power=power+p[i,absorb[i]+1];time= time+i*p[i,absorb[i]+1]}
signaltime<- time/power
surveillancetime<- time + N*(1-power)

result<- list(power,signaltime,surveillancetime)
names(result)<- c("Power","ESignaltime","ESampleSize")
return(result)


             } # CLOSES THE PART FOR THE CONTINUOUS CASE
##########################################################################################
##########################################################################################


#################################################################################################################################
######################### HERE IS THE PART FOR GROUP SEQUENTIAL ANALYSIS (GroupSizes!=1)####################################


if(auxgroup==1){ # OPENS THE PART FOR THE GROUP CASE



if(Tailed!="upper"){stop("For this version of the Sequential package, Performance.Binomial works only for 'Tailed=upper'.",call. =FALSE)}

Groups<- GroupSizes
alpha<- 0.05
MinCases<- M
# N = maximum length of surveillance defined in terms of the total number of adverse events
# alpha = desired alpha level
# MinCases = The minimum number of cases for which a signal is allowed to occur, default=1
# z = matching ratio between exposed and unexposed cases 
# probability of having a case under the null hypothesis   
# Groups: Vector with the number of adverse events (exposed+unexposed) between two looks at the data, i.e, irregular group sizes. Important: Must sums up N
# RR= Relative risk 


if(p=="n"&z=="n"){stop("Please, at least z or p must be provided.",call. =FALSE)}

if( z!="n"){if(sum(is.numeric(z))!=1){stop("Symbols and texts are not applicable for 'z'. It must be a number greater than zero.",call. =FALSE)}}
if(z<=0){stop("'z' must be a number greater than zero.",call. =FALSE)}

if(p!="n"){
if(is.numeric(p)!=TRUE){stop("Symbols and texts are not applicable for 'p'. It must be a probability measure.",call. =FALSE)}
if(z!="n"){if(p!= 1/(1+z)){stop("Both z and p are specified, but the required relationship that p=1/(1+z) does not hold. Please remove either the definition of z or the definition of p. Only one of them is needed. .",call. =FALSE)}}
if(p<=0|p>=1){stop("p must be a number greater than zero and smaller than 1.",call. =FALSE)}
           }

if(z!="n"){z<- z}else{z<- 1/p-1}


if(length(Groups)==1){
if(is.numeric(Groups)==FALSE){stop("'Groups' must be an integer smaller than or equal to 'N'.",call. =FALSE)}
if(Groups==0){stop("'N' must be a positive integer'.",call. =FALSE)}
if(N/Groups!=round(N/Groups)){stop("'N' must be a multiple of 'Groups'.",call. =FALSE)}
if(Groups>N){stop("'N' must be a multiple of 'Groups'.",call.=FALSE)}
}

if(length(Groups)>1){
if(sum(is.numeric(Groups))==0){stop("'Groups' must be a vector of positive integers.",call. =FALSE)}else{
if(sum(Groups)!=N){stop("'Groups' must sums up 'N'.",call. =FALSE)}
if(sum(Groups<0)>0){stop("The vector 'Groups' must contain only positive integers.",call. =FALSE)}
}
}
if((N<=0|is.numeric(N)==FALSE)){stop("'N' must be a positive integer.",call. =FALSE)}
if(alpha<=0|alpha>0.5||is.numeric(alpha)==FALSE){stop("'alpha' must be a number greater than zero and smaller than 0.5.",call. =FALSE)}
if(MinCases>N||is.numeric(MinCases)==FALSE){stop("'M' must be an integer smaller than or equal to N.",call. =FALSE)}
if(MinCases<1){stop("'M' must be an integer greater than zero.",call. =FALSE)}
if(MinCases!=round(MinCases)){stop("'M' must be an integer.",call. =FALSE)}
if(cv<0||is.numeric(cv)==FALSE|length(cv)>1){stop("cv must be a number greater than zero.",call. =FALSE)}
if(RR<1||is.numeric(RR)==FALSE){stop("RR must be a number greater than or equal to 1.",call. =FALSE)}
if(round(N)!=N){stop("'N' must be a positive integer.",call. =FALSE)}
if(round(M)!=M){stop("'M' must be a positive integer.",call. =FALSE)}

pst<- 1/(1+z)


if(length(Groups)>1){an<- Groups%*%(upper.tri(matrix(0,length(Groups),length(Groups)),diag=T)*1)}else{an<- seq(Groups,N,Groups)
                                                                                                      if(max(an)<N){an<- c(an,N)}
                                                                                                     }

# Function that calculates the LLR for a given observed (c) and expected (u) number of cases
#-------------------------------------------------------------------------------------------
LLR <- function(cc,n,z){

       if(cc==n){x = n*log(1+z)}else{
         if(z*cc/(n-cc)<=1){x=0}else{
	       x = cc*log(cc/n)+(n-cc)*log((n-cc)/n)-cc*log(1/(z+1))-(n-cc)*log(z/(z+1))
                                    }
                                  } 	
      	x
	                }

# absorb[i]: number of acumulated cases (from the exposed period) needed to reject the null at the i-th adverse event 
# aux[i]: has zero entree if LLR(absorb[i],i,z)< cv or has 1 entree otherwise
# an[kk]:  order of the adverse event associated to the kk-th test

absorb = rep(0,N)		# Contains the number of events needed at time mu[i] in order to reject H0
aux<- rep(0,N)

for(i in 1:N){
      if(sum(an==i)>0){
	while( LLR(absorb[i],i,z)<cv &absorb[i]<i){ 
		absorb[i]=absorb[i]+1               }
             if(LLR(absorb[i],i,z)>=cv){aux[i]<- 1}
                      }else{absorb[i]<- i+1}
             }

if(MinCases>1){
aux[1:(MinCases-1)]<- 0
              }


for(i in 1:N){if(absorb[i]<MinCases&i>=MinCases){absorb[i]<- MinCases};if(absorb[i]<MinCases&i<MinCases|aux[i]==0){absorb[i]<- i+1}}

uc<- absorb-1

ps<- RR/(RR+z)

# Auxiliar functions to run the binomial Markov Chain in a fast way:
func_aux2<- function(j,i){ k<- seq(1,uc[i-1]+1); return(sum(p[i-1,k]*dbinom(j-k,1,ps)))} ; func_aux3<- function(i){ k<- seq(1,uc[i-1]+1); return(sum(p[i-1,k]*(1-pbinom(absorb[i]-k,1,ps))))}
func_aux1<- function(i){ j<- matrix(seq(1,absorb[i]),ncol=1) ; return(apply(j,1,func_aux2,i))}

p<- matrix(0,N,N+2)    	# p[i,j] is the probability of having j-1 cases at time mu[i]
									# starting probabilities are all set to zero's


# Calculating the first row in the p[][] matrix for which there is a chance to reject H0
# --------------------------------------------------------------------------------------

for(s in 1:absorb[1]){ p[1,s]=dbinom(s-1,1,ps)}		# Probability of having s-1 cases at time mu[1]
p[1,absorb[1]+1]=1-pbinom(absorb[1]-1,1,ps)			# probability of rejecting H0 at time mu[1]

if(N>1){
i<- 1

while(i<N){
i<- i+1
       p[i,1:absorb[i]]<- func_aux1(i) # Calculates the standard p[][] cell values
       p[i,absorb[i]+1]<- func_aux3(i) # Calculates the diagonal absorbing states where H0 is rejected
 
          } # end for i
     }	

# Sums up the probabilities of absorbing states when a signal occurs, to get the alpha level
# ------------------------------------------------------------------------------------------

power=0
time<- 0
for(i in 1:N){ 
                                    power=power+p[i,absorb[i]+1]
                                    time<- time + i*p[i,absorb[i]+1]
                                          
             }					
	signaltime<- time/power
      surveillancetime<- time + N*(1-power)

result<- list(power,signaltime,surveillancetime)
names(result)<- c("Power","ESignalTime","ESampleSize")
return(result)

             } # CLOSES THE PART FOR THE GROUP CASE
##########################################################################################
##########################################################################################

} #end function Performance.Binomial


## EXAMPLE

# Performance.Binomial(N,M=1,cv=3,z=1,p="n",RR=2,GroupSizes=1,Tailed="upper")




