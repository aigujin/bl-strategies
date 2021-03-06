
source('lib/BL-functions.R')
#stocks <- sort(unique(unlist(lapply(market.list,function(m){m$stock.names}))))
#quarters <- setnames(unique(market.set[,.(Quarters)]),'q.id')[,q.id:=as.yearqtr(q.id)]

quarters <- setnames(data.table(unique(ranked.pt.dt[,q.id])),'q.id')[,q.id:=as.yearqtr(q.id)]

#core.dt <- na.omit(setkey(na.omit(q.data),q.id)[setkey(quarters,q.id)])[,core.b:=.N>=12,by=list(Stock,Broker)][(core.b)][,true:=rank(score),by=list(q.id,Stock)][,core.s:=.N>=3,by=list(q.id,Stock)][(core.s)][,core.q:=length(unique(q.id))>=8,by=.(Stock)][(core.q)]



pt.ret <-setkey(melt(core.dt[,merge(setkey(quarters,q.id),.SD,all=T),by=list(Broker,Stock),.SDcols=c('q.id','Broker','Stock','b.view')][,.(q.id,Broker,Stock,b.view)][,true:=truncate.f(b.view,percentile)][,naive:=c(NA,head(true,-1))][,':='(default=grow.window.f(true,seq_len(length(true)),mean,na.rm=T),raw=true,'1diff'=true,roll.sd=true,random=true),by=.(Broker,Stock)],id.vars = c('q.id','Stock','Broker'),measure.vars = c(baselines,methods),value.name = 'exp.ret',variable.name = 'Method'),q.id,Stock,Broker,Method)[ranked.pt.dt][,rank.exp.ret.f(rank,exp.ret),by=.(q.id,Stock,Method)][V1!=0,]

pt.list.rank <- acast(pt.ret,q.id~Stock~Method,value.var='V1')


require(scales)

res.accu <- melt(setkey(melt(unique(core.dt,by=c('q.id','Stock'),fromLast = T)[,.(q.id,Stock,s.coefVar)][,true:=0][,':='(naive=c(NA,head(s.coefVar,-1)),default=grow.window.f(s.coefVar,seq_len(length(s.coefVar)),mean,na.rm=T),raw=NA_real_,'1diff'=NA_real_,roll.sd=NA_real_,random=NA_real_),by=Stock],id.vars = c('q.id','Stock'),measure.vars=c(baselines,methods),value.name='cons'),q.id,Stock,variable)[setkey(pt.accu[,':='(last=omega.f(value),ma={tmp <- grow.window.f(value,4,mean,na.rm=T);omega.f(tmp)}),by=Stock],q.id,Stock,variable)],id.vars=c('q.id','Stock','variable'),measure.vars=confid.id,variable.name='conf')[variable=='true',value:=0]

set(res.accu,i=which(is.infinite(res.accu[[5L]])),5L,value=9e+15 )


conf.coef <- acast(res.accu,q.id~Stock~variable~conf,value.var='value')

pt.stocks <- intersect(dimnames(pt.list.rank)[[2]],dimnames(conf.coef)[[2]])


bl.period <- 1:dim(pt.list.rank)[[1]]
m.period <-(length(market.list)-length(bl.period)+1) : (length(market.list))

opt.w<- rbindlist(lapply(confid.id, function(i){
        opt.w.f(pt.list.rank,conf.coef[,pt.stocks,,i],tau)[,confAgg:=i]}))[,Views:='TP']


final.bl <- setkey(unique(pred.bl.results.f(opt.w),by=c('Method','q.id','Views','confAgg')),Method)
final.bl$Method <- factor(final.bl$Method,levels=unique(final.bl$Method)[c(8,4,3,6,1,5,7,2)])
final.bl$Views <- factor(final.bl$Views,levels=unique(final.bl$Views)[c(2,1)])
colourCount = length(unique(final.bl$Method))
getPalette = colorRampPalette(RColorBrewer::brewer.pal(colourCount, "Set1"))
