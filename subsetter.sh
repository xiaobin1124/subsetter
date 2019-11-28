#!/bin/sh
# regrid output for specific Region, xiaob 20190129
# Original z-level
set -x
ymdh=$1
fname_dir=$2
data_prefix=17
#res_dir=${F_HOME}dataout/$ymdh
fname=`basename ${fname_dir}`
vname=$3
echo $fname_dir
#echo $res_dir
echo $fname
dir0=/SUGONP300-1/data_collab/Solomon
out_dir_tmp=${dir0}/tmp/$ymdh
dataout=${dir0}/$ymdh
jnl_dir=${dir0}/jnl
jnl=${dir0}/$fname.jnl
do_regrid_vname=(temp salt u v)
do_regrid_z=0
#for i in $do_regrid_vname;do
for i in `seq 0 $((${#do_regrid_vname[*]}-1))`;do
  if [[ $vname == *${do_regrid_vname[$i]}* ]];then
    do_regrid_z=1
    var_out=$vname
    xcoor=XT_OCEAN      #default value of xcoor
    scale_factor=1.     #default value of scale_factor
    add_offset=0.       #default value of add_offset
    outtype=float       #default value of outtype
    if [[ $vname == *u* ]] || [[ $vname == *v* ]];then
    #  fname=tco.$fname 
      xcoor=XU_OCEAN
      scale_factor=0.0005
      add_offset=0.
      outtype=short
    fi
    if [[ $vname == *salt* ]];then
      xcoor=XT_OCEAN
      scale_factor=0.001
      add_offset=25.
      outtype=short
    fi
    if [[ $vname == *temp* ]];then
      xcoor=XT_OCEAN
      scale_factor=0.00125
      add_offset=30.
      outtype=short
    fi
  fi
done
fname_dir=`dirname $fname_dir`/$fname
echo $fname_dir
if [ $do_regrid_z != 1 ];then
  exit 0
fi
if [ ! -d $out_dir_tmp ];then
  mkdir -p $out_dir_tmp
fi
if [ ! -d $dataout ];then
  mkdir -p $dataout
fi
if [ ! -d ${jnl_dir} ];then
  mkdir -p ${jnl_dir}
fi
echo Run.regrid_mmd: $fname

xregion="x=145.0:165.0"
yregion="y=-15.:-4."
zregion="z=1:1000"

#zlev="1,10,20,30,40,50,75,80,100,125,150,200,250,300,400,500"

cat > $jnl << EOF
use "$fname_dir"
set mem/size=2000
set axis/modulo $xcoor
!define axis/$xregion/units=degree_east xax
!define axis/$yregion/units=degree_north yax
!define axis/z zax={$zlev}
!define grid/x=xax/y=yax/z=zax gg
set region/$xregion/$yregion/$zregion

let vmax=32767*$scale_factor+$add_offset
let vmin=-32767*$scale_factor+$add_offset
let ${var_out}0=${var_out}
let ${var_out}1= IF ( ${var_out}0 LT vmax and ${var_out}0 GT vmin ) THEN ${var_out}0 ELSE (-32768*$scale_factor+$add_offset)
define att ${var_out}1.scale_factor = $scale_factor
define att ${var_out}1.add_offset = $add_offset
set var/outtype=$outtype/bad=-32768 ${var_out}1
save/file="$out_dir_tmp/d${data_prefix}.${fname}"/clobber ${var_out}1
EOF
ferret -script $jnl
if [ $? -ne 0 ];then exit 1;fi
#nccopy -d6 $out_dir/d12.${fname} $dataout/d12.${fname}
mv $out_dir_tmp/d${data_prefix}.${fname} $dataout/d${data_prefix}.${fname}
gzip $dataout/d${data_prefix}.${fname}
#rm $out_dir/d12.${fname}
rm $jnl
