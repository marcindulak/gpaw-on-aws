# Cluster runtype price(16cores)/hour, libraries used, cpu type
#echo '# Niflheim xeon16.acml.SL 3500./16/(24*30), acml-4.4.0  ScaLapack 2.0.2, 16 cores Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz'
#python scaling.py -v --dir=xeon16.acml.SL --pattern="xeon16.acml.SL_*_" b256H2O
#echo
echo '# Niflheim xeon16.openblas.SL 3500./16/(24*30), openblas-0.2.13 ScaLapack 2.0.2, 16 cores Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz'
python scaling.py -v --dir=xeon16.openblas.SL --pattern="xeon16.openblas.SL_*_" b256H2O
echo
#echo '# Niflheim xeon16.openblas 3500./16/(24*30), openblas-0.2.13, no ScaLapack: 16 cores Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz'
#python scaling.py -v --dir=xeon16.openblas --pattern="xeon16.openblas_*_" b256H2O
#echo

echo '# AWS m3.2xlarge 0.632*2, openblas-0.2.14 ScaLapack 2.0.2, 8 cores Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz ECU 26'
python scaling.py -v --dir=m3.2xlarge.openblas.SL --pattern="m3.2xlarge.openblas.SL_*_" b256H2O
echo
echo '# AWS m4.xlarge 0.3*4, openblas-0.2.14 ScaLapack 2.0.2, 4 cores Intel(R) Xeon(R) CPU E5-2676 v3 @ 2.40GHz ECU 13'
python scaling.py -v --dir=m4.xlarge.openblas.SL --pattern="m4.xlarge.openblas.SL_*_" b256H2O
echo
echo '# AWS d2.4xlarge 3.176, openblas-0.2.14 ScaLapack 2.0.2, 16 cores Intel(R) Xeon(R) CPU E5-2676 v3 @ 2.40GHz ECU 56'
python scaling.py -v --dir=d2.4xlarge.openblas.SL --pattern="d2.4xlarge.openblas.SL_*_" b256H2O
echo
echo '# AWS c4.4xlarge 1.125, openblas-0.2.14 ScaLapack 2.0.2, 16 cores Intel(R) Xeon(R) CPU E5-2666 v3 @ 2.90GHz ECU 62'
python scaling.py -v --dir=c4.4xlarge.openblas.SL --pattern="c4.4xlarge.openblas.SL_*_" b256H2O
echo
#echo '# AWS c4.4xlarge 1.125, openblas-0.2.14, no ScaLapack: 16 cores Intel(R) Xeon(R) CPU E5-2666 v3 @ 2.90GHz ECU 62'
#python scaling.py -v --dir=c4.4xlarge.openblas --pattern="c4.4xlarge.openblas_*_" b256H2O
#echo
#echo '# AWS c4.4xlarge 1.125, acml-4.4.0, no ScaLapack: 16 cores Intel(R) Xeon(R) CPU E5-2666 v3 @ 2.90GHz ECU 62'
#python scaling.py -v --dir=c4.4xlarge.acml --pattern="c4.4xlarge.acml_*_" b256H2O

