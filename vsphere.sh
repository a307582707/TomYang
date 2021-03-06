#!/bin/sh
skip=44

tab='	'
nl='
'
IFS=" $tab$nl"

umask=`umask`
umask 77

gztmpdir=
trap 'res=$?
  test -n "$gztmpdir" && rm -fr "$gztmpdir"
  (exit $res); exit $res
' 0 1 2 3 5 10 13 15

if type mktemp >/dev/null 2>&1; then
  gztmpdir=`mktemp -dt`
else
  gztmpdir=/tmp/gztmp$$; mkdir $gztmpdir
fi || { (exit 127); exit 127; }

gztmp=$gztmpdir/$0
case $0 in
-* | */*'
') mkdir -p "$gztmp" && rm -r "$gztmp";;
*/*) gztmp=$gztmpdir/`basename "$0"`;;
esac || { (exit 127); exit 127; }

case `echo X | tail -n +1 2>/dev/null` in
X) tail_n=-n;;
*) tail_n=;;
esac
if tail $tail_n +$skip <"$0" | gzip -cd > "$gztmp"; then
  umask $umask
  chmod 700 "$gztmp"
  (sleep 5; rm -fr "$gztmpdir") 2>/dev/null &
  "$gztmp" ${1+"$@"}; res=$?
else
  echo >&2 "Cannot decompress $0"
  (exit 127); res=127
fi; exit $res
��%W_vsphere.sh �U�n�6��)Xɇ���N#��@��`Ql���--R�THʱz�}���[/{�qo}���[tF�{�>���Ǚ��7��φKe�K�s2�Eu�j[������iD��&�^�hR������_�����?��UD��!*�o� ��lFs���4$^���jOE�����`L e�[�$���u!n��h���$2�-��\����������CD2E�������K%�LiI�3��5wCW�a��~� Dbo�[(�$A$<p��!T�e�!1���J��!(��[+��n-]���)Ti]�狋єļ
6�E��4&q�s�� �H�=;�BvU,'�V���B2'��k�*�����e�G�h4�ٙtκ�+8n<o�LA(�O�}}=�|��b������h�a�*˰"�&<_��d�/��/��[m��6?���K�J�t�畁+b��dA����Ce�\��6dߓ*Ƌ��̑K����o?ڮN�
�IӨ���������n�xV� cw�t5�h�$�5�ΆW ��)�5=
��6.b��g�Vy(�)#�F�m�k�rQ�||�A҄�n�94��;�Ά ��d&h�ܔ�I,�3�k4�Ԃ�r��f� �V�[�y��2���֫`]ޛ���qp����(� H`���IѶ�2Ɗ%Pk���ի��~	ʳc�˓^e�E&m�|u�-0�l�U�K�,��*{oz@�*�Sn��eȱ�f;��,�%*`&q1�)��ЭA�ة���Wl�lU�܂ttڧ���d�u�0Ϲ�5�?��j9���HNa��5�2�6Lj
�����.�˞�����b?����� ��k����Lmz����V�I�ֽ���	E��v�����ܠ��j;�D[�J �,kH������k�uk�*�u�T�DT&
����1�U���u���<$���44<��a�%7�y�L����dS�^K�-�C/j;c���8˜�jg��	��~����R�b�L�z-���T��r:���Ԏ�  