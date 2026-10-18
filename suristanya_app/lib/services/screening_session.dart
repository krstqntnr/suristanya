/// In-memory store for the current screening session.
/// Reset when the user starts a new scan.
class ScreeningSession {
  ScreeningSession._();
  static final ScreeningSession instance = ScreeningSession._();

  // Demographics
  String? sex; // 'male' | 'female' | null
  bool pregnant = false;
  int? age;

  // Selections
  final Set<String> symptoms = {};
  final Set<String> riskFactors = {};

  // Labs (optional)
  num? ferritin;
  num? hemoglobin;
  num? mcv;
  num? mch;
  num? rdw;
  num? tsat;
  num? crp;

  bool get hasAnyLab =>
      ferritin != null ||
      hemoglobin != null ||
      mcv != null ||
      mch != null ||
      rdw != null ||
      tsat != null ||
      crp != null;

  Map<String, dynamic> toJson() {
    final labs = <String, num>{};
    if (ferritin != null) labs['ferritin'] = ferritin!;
    if (hemoglobin != null) labs['hemoglobin'] = hemoglobin!;
    if (mcv != null) labs['mcv'] = mcv!;
    if (mch != null) labs['mch'] = mch!;
    if (rdw != null) labs['rdw'] = rdw!;
    if (tsat != null) labs['tsat'] = tsat!;
    if (crp != null) labs['crp'] = crp!;

    return {
      'sex': sex,
      'pregnant': pregnant,
      'age': age,
      'symptoms': symptoms.toList(),
      'risk_factors': riskFactors.toList(),
      'labs': labs,
    };
  }

  void reset() {
    sex = null;
    pregnant = false;
    age = null;
    symptoms.clear();
    riskFactors.clear();
    ferritin = null;
    hemoglobin = null;
    mcv = null;
    mch = null;
    rdw = null;
    tsat = null;
    crp = null;
  }
}
