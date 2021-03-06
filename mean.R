#Getting data
amt<-dbGetQuery(con,statement='select Mobile,Dt,GROSS_Amount as Amount from sku_data where (Mobile!=\'NULL\' and SUB_CATEGORY!=\'CARRY BAG\' and DEPARTMENT!=\'NULL\' and Qty>0)')
amt<-data.table(amt)

#Data Processing
amt<-amt[,.(Totamt=sum(Amount)),by=list(Mobile,Dt)]
amt$Dt<-NULL
tab<-amt[,.(Avgamt=mean(Totamt)),by=list(Mobile)]

tab<-merge(x = tab, y = amt, by = "Mobile", all=TRUE)

tab$min1<-tab$Avgamt-.1*tab$Avgamt
tab$max1<-tab$Avgamt+.1*tab$Avgamt

tab$min2<-tab$Avgamt-.2*tab$Avgamt
tab$max2<-tab$Avgamt+.2*tab$Avgamt

#Function
taba = tab[as.numeric(tab$Totamt) <= as.numeric(tab$max1),]
taba = taba[as.numeric(taba$Totamt) >= as.numeric(taba$min1),]
taba$num<-1
taba<-taba[, .(nearmeantrans10 = sum(num)), by = list(Mobile)]

tabb = tab[as.numeric(tab$Totamt) <= as.numeric(tab$max2),]
tabb = tabb[as.numeric(tabb$Totamt) >= as.numeric(tabb$min2),]
tabb$num<-1
tabb<-tabb[, .(nearmeantrans20 = sum(num)), by = list(Mobile)]

tab<-merge(x = taba, y = tabb, by = "Mobile", all=TRUE)

#write tqble to sql
dbWriteTable(con,"temptab",tab,overwrite=T)
dbGetQuery(con,statement='ALTER TABLE temptab ADD PRIMARY KEY (Mobile(15))')

#alter final
dbGetQuery(con,statement='update masterfile f inner join temptab t on t.mobile = f.mobile set f.trans_meanamt_greater10 = t.nearmeantrans10')
dbGetQuery(con,statement='update masterfile f inner join temptab t on t.mobile = f.mobile set f.trans_meanamt_greater20 = t.nearmeantrans20')

#Cleaning
rm(amt)
rm(tab)
rm(taba)
rm(tabb)
