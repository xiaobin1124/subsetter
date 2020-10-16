#!/bin/sh
# regrid output for specific Region, xiaob 20190129
# Original z-level
set -x
set -e
#ymdh=$1
if [[ $# -ne 3 ]];then
  echo Manditory input options: directory of filename, varname and config file.
  echo example: ./subsetter.sh /path/to/file/19800101.ocean_temp.nc temp config_file
  exit 1
fi
fname_dir=$1
output_prefix=d17
#res_dir=${F_HOME}dataout/$ymdh
fname=`basename ${fname_dir}`
vname=$2
config_file=$3
echo $fname_dir
#echo $res_dir
echo $fname
output_dir=/SUGONP300-1/data_collab1/zhangzx
do_regrid_vname=(temp salt u v)
var_out=$vname
#xregion="x=145.0:165.0"
#yregion="y=-15.:-4."
#zregion="z=1:1000"

if [ ! -f $config_file ];then
  echo "please confirm config_file: $config_file exits!"
  exit 1
fi
xcoor=XT_OCEAN      #default value of xcoor
scale_factor=1.     #default value of scale_factor
add_offset=0.       #default value of add_offset
outtype=float       #default value of outtype
source `dirname $config_file`/`basename $config_file`
#out_dir_tmp=${output_dir}/tmp/$ymdh
out_dir_tmp=${output_dir}/tmp/
#dataout=${output_dir}/$ymdh
if [ ! -d $output_dir ];then
  mkdir -p $output_dir
fi
dataout=${output_dir}/
jnl=${output_dir}/$fname.jnl

if [[ ${vname,,} == *u* ]] || [[ ${vname,,} == *v* ]];then
#  fname=tco.$fname 
  #xcoor=XU_OCEAN
  scale_factor=0.0005
  add_offset=0.
  outtype=short
fi
if [[ ${vname,,} == *salt* ]];then
  #xcoor=XT_OCEAN
  scale_factor=0.001
  add_offset=25.
  outtype=short
fi
if [[ ${vname,,} == *temp* ]];then
  #xcoor=XT_OCEAN
  scale_factor=0.00125
  add_offset=30.
  outtype=short
fi
fname_dir=`dirname $fname_dir`/$fname
echo $fname_dir
if [ ! -d $out_dir_tmp ];then
  mkdir -p $out_dir_tmp
fi
if [ ! -d $dataout ];then
  mkdir -p $dataout
fi
echo Run.regrid_mmd: $fname


#zlev="1,10,20,30,40,50,75,80,100,125,150,200,250,300,400,500"
if [ -z $zlev ];then #IF

cat > $jnl << EOF
CANCEL MODE upcase_output
use "$fname_dir"
set mem/size=2000
set axis/modulo $xcoor
!define axis/$xregion/units=degree_east xax
!define axis/$yregion/units=degree_north yax
!define axis/z zax={$zlev}
!define grid/x=xax/y=yax/z=zax gg
set region/$xregion/$yregion/$zregion/$tregion

let vmax=32767*$scale_factor+$add_offset
let vmin=-32767*$scale_factor+$add_offset
let ${var_out}0=${var_out}
let ${var_out}1= IF ( ${var_out}0 LT vmax and ${var_out}0 GT vmin ) THEN ${var_out}0 ELSE (-32768*$scale_factor+$add_offset)
define att ${var_out}1.scale_factor = $scale_factor
define att ${var_out}1.add_offset = $add_offset
set var/outtype=$outtype/bad=-32768 ${var_out}1
save/file="$out_dir_tmp/${output_prefix}.${fname}"/clobber ${var_out}1
EOF

else                  #else 

cat > $jnl << EOF
CANCEL MODE upcase_output
use "$fname_dir"
set mem/size=2000
set axis/modulo $xcoor
!define axis/$xregion/units=degree_east xax
!define axis/$yregion/units=degree_north yax
define axis/z zax={$zlev}
define grid/z=zax ggz
set region/$xregion/$yregion/$zregion

let vmax=32767*$scale_factor+$add_offset
let vmin=-32767*$scale_factor+$add_offset
let ${var_out}0=${var_out}
let ${var_out}1= IF ( ${var_out}0 LT vmax and ${var_out}0 GT vmin ) THEN ${var_out}0 ELSE (-32768*$scale_factor+$add_offset)
define att ${var_out}1.scale_factor = $scale_factor
define att ${var_out}1.add_offset = $add_offset
set var/outtype=$outtype/bad=-32768 ${var_out}1
save/file="$out_dir_tmp/${output_prefix}.${fname}"/clobber ${var_out}1[gz=ggz]
EOF

fi                    #FI
sed -i 's/\/\/\/\/$//g' $jnl;sed -i 's/\/\/\/$//g' $jnl;sed -i 's/\/\/$//g' $jnl;sed -i 's/\/$//g' $jnl;sed -i 's/\/\//\//g' $jnl;sed -i 's/\/\//\//g' $jnl;sed -i 's/\/\/\//\//g' $jnl
ferret -script $jnl
if [ $? -ne 0 ];then exit 1;fi
#nccopy -d6 $out_dir/d12.${fname} $dataout/d12.${fname}
mv $out_dir_tmp/${output_prefix}.${fname} $dataout/${output_prefix}.${fname}
#gzip $dataout/${output_prefix}.${fname}
nccopy -d6 $dataout/${output_prefix}.${fname} $dataout/${output_prefix}.${fname}.d6
mv $dataout/${output_prefix}.${fname}.d6 $dataout/${output_prefix}.${fname}
ncrename -h -v ${var_out}1,${var_out} -O $dataout/${output_prefix}.${fname}
#rm $out_dir/d12.${fname}
rm $jnl
#rm -r $out_dir_tmp
exit 0
