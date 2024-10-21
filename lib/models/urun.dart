class Urun {
  final String isim;
  final num miktar;
  final String miktarTuru;

  Urun(this.isim, this.miktar, this.miktarTuru);

  Urun.fromMap(Map<String, dynamic> json)
      : isim = json['isim'],
        miktar = json['miktar'],
        miktarTuru = json['miktarTuru'];
}
