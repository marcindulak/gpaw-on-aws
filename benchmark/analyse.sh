echo '# Niflheim xeon16: Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz '
python scaling.py -v --dir=xeon16 --pattern="xeon16_*_" b256H2O
echo '# AWS m4.xlarge: Intel(R) Xeon(R) CPU E5-2676 v3 @ 2.40GHz'
python scaling.py -v --dir=m4.xlarge --pattern="m4.xlarge_*_" b256H2O
