{
  python3,
  fetchFromGitHub,
  lib,
  ffmpeg,
  gifsicle,
  libjpeg,
  libavif,
}:
let
  jpegiptc = python3.pkgs.buildPythonPackage rec {
    pname = "jpegiptc";
    version = "1.5";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "gdegoulet";
      repo = "JpegIPTC";
      tag = "v${version}";
      hash = "sha256-5yWDDF0JFGY3JxvvyHj7bLGjwo/tJM2ZqN0AmSQdZjs=";
    };

    build-system = [
      python3.pkgs.setuptools
      python3.pkgs.wheel
    ];

    pythonImportsCheck = [
      "JpegIPTC"
    ];

    meta = {
      description = "The purpose is to extract APP13 (iptc data) from image and raw copy APP13 to another image";
      homepage = "https://github.com/gdegoulet/JpegIPTC";
      license = lib.licenses.mit;
      maintainers = [ lib.maintainers.sephi ];
    };
  };

  thumbor-plugins-gifv =
    let
      version = "0.1.5";

      repo = fetchFromGitHub {
        owner = "thumbor";
        repo = "thumbor-plugins";
        tag = "thumbor-plugins-gifv-v${version}";
        hash = "sha256-P1EhAUTIyjAY5nXYoB7F67QqQHlxdz7JzRoPcRFN8f0=";
      };
    in
    python3.pkgs.buildPythonPackage rec {
      pname = "thumbor-plugins-gifv";
      inherit version;

      pyproject = true;

      build-system = [
        python3.pkgs.setuptools
      ];

      dependencies = [ python3.pkgs.webcolors ];

      pythonRelaxDeps = [ "webcolors" ];

      src = "${repo}/thumbor_plugins/optimizers/gifv";

      meta = {
        description = "Gifv plugin for Thumbor";
        homepage = "https://github.com/thumbor/thumbor-plugins/tree/master/thumbor_plugins/optimizers/gifv";
        license = lib.licenses.mit;
        maintainers = [ lib.maintainers.sephi ];
      };
    };

  pillow-avif-plugin = python3.pkgs.buildPythonPackage rec {
    pname = "pillow-avif-plugin";
    version = "1.5.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "fdintino";
      repo = "pillow-avif-plugin";
      tag = "v${version}";
      hash = "sha256-gdDVgVNympxlTzj1VUqO+aU1/xWNjDm97a0biOTlKtA=";
    };

    build-system = [ python3.pkgs.setuptools ];

    buildInputs = [ libavif ];

    dependencies = [ python3.pkgs.pillow ];

    nativeCheckInputs = [ python3.pkgs.pytestCheckHook ];

    meta = {
      description = "Pillow plugin that adds support for AVIF files";
      homepage = "https://github.com/fdintino/pillow-avif-plugin";
      license = lib.licenses.bsd2;
    };
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "thumbor";
  version = "7.7.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "thumbor";
    repo = "thumbor";
    tag = version;
    hash = "sha256-rTQcOkkratFmqXnGkZK/434WmuTXS3Rb+J8jbZ7S6ZA=";
  };

  build-system = [
    python3.pkgs.setuptools
  ];

  # Thumbor depends on `remotecv` for queued detection, however `remotecv`
  # depends on `pyres` which has been removed from nixpkgs because it’s
  # abandoned. The package still works fine without `remotecv` as long as
  # queued detection is not configured.
  dependencies = with python3.pkgs; [
    colorama
    derpconf
    jpegiptc
    libthumbor
    piexif
    pillow
    pillow-avif-plugin
    pillow-heif
    pycurl
    pytz
    opencv-python-headless
    statsd
    thumbor-plugins-gifv
    tornado
    webcolors
  ];

  optional-dependencies = {
    svg = [ python3.pkgs.cairosvg ];
  };

  pythonRelaxDeps = [
    "pillow"
    "pytz"
    "setuptools"
    "webcolors"
  ];

  buildInputs = [
    libjpeg
    ffmpeg
  ];

  nativeCheckInputs = [
    python3.pkgs.pytestCheckHook
    gifsicle
    libjpeg
    ffmpeg
  ];

  checkInputs = with python3.pkgs; [
    cairosvg
    preggy
    pyssim
    pytest-asyncio
    sentry-sdk
    redis
  ];

  preCheck = ''
    # Cleaning up the thumbor directory is necessary to avoid errors with
    # Python extension modules
    find thumbor -type f -name '*.py' -delete
  '';

  disabledTestPaths = [
    # Depends on remotecv which in turn depends on pyres, which is abandoned
    "tests/detectors/test_queued_detector.py"
  ];

  disabledTests = [
    # Checks existence of /bin/ls
    "test_can_which_by_path"
    # Error probably due to the mock object not matching the object in the Sentry SDK version in nixpkgs
    "test_when_error_occurs_should_have_called_client"
    # Not sure how this test is supposed to pass
    "test_watermark_filter_detect_extension_simple"
  ];

  pythonImportsCheck = [
    "thumbor"
  ];

  meta = {
    description = "Thumbor is an open-source photo thumbnail service by globo.com";
    homepage = "https://github.com/thumbor/thumbor/";
    changelog = "https://github.com/thumbor/thumbor/blob/${src.rev}/CHANGELOG";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.sephi ];
    mainProgram = "thumbor";
  };
}
