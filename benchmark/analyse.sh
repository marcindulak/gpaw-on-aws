echo '# Niflheim xeon16'
python scaling.py -v --dir=xeon16 --pattern="xeon16_*_" b256H2O
echo '# AWS m4.xlarge'
python scaling.py -v --dir=m4.xlarge --pattern="m4.xlarge_*_" b256H2O
