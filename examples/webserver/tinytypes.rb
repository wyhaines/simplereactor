# This library is a massively abbreviated, and slightly altered version of a very old version
# of Austin Ziegler's full featured Mine::Types (https://github.com/halostatue/mime-types)
# library. This version is intended only to provide the most basic functionality for dealing
# with MIME Typing.

module MIME

  class InvalidContentType < RuntimeError; end

  # The definition of one MIME content-type.
  #
  # == Usage
  #  require 'mime/types'
  #
  #  plaintext = MIME::TinyTypes['text/plain']
  #  print plaintext.media_type           # => 'text'
  #  print plaintext.sub_type             # => 'plain'
  #
  #  puts plaintext.extensions.join(" ")  # => 'asc txt c cc h hh cpp'
  #
  #  puts plaintext.encoding              # => 8bit
  #  puts plaintext.binary?               # => false
  #  puts plaintext.ascii?                # => true
  #  puts plaintext == 'text/plain'       # => true
  #  puts MIME::TinyType.simplified('x-appl/x-zip') # => 'appl/zip'
  
  class TinyType
    include Comparable

    MEDIA_TYPE_RE = %r{([-\w.+]+)/([-\w.+]*)}o
    UNREG_RE      = %r{[Xx]-}o
    ENCODING_RE   = %r{(?:base64|7bit|8bit|quoted\-printable)}o
    PLATFORM_RE   = %r|#{RUBY_PLATFORM}|o

    SIGNATURES    = %w(application/pgp-keys application/pgp
                       application/pgp-signature application/pkcs10
                       application/pkcs7-mime application/pkcs7-signature
                       text/vcard)

    def like?(other)
      if other.respond_to?(:simplified)
        @simplified == other.simplified
      else
        @simplified == TinyType.simplified(other)
      end
    end

    def <=>(other) #:nodoc:
      if other.respond_to?(:content_type)
        @content_type.downcase <=> other.content_type.downcase
      elsif other.respond_to?(:to_s)
        @simplified <=> TinyType.simplified(other.to_s)
      else
        @content_type.downcase <=> other.downcase
      end
    end

    def eql?(other) #:nodoc:
      other.kind_of?(MIME::TinyType) and self == other
    end

    attr_reader :content_type
    attr_reader :media_type
    attr_reader :raw_media_type
    attr_reader :sub_type
    attr_reader :raw_sub_type
    attr_reader :simplified
    attr_accessor :extensions
    remove_method :extensions= ;
    def extensions=(ext)
      @extensions = ext.to_a.flatten.compact
    end

    def default_encoding
      (@media_type == 'text') ? 'quoted-printable' : 'base64'
    end

    class << self
      def simplified(content_type)
        matchdata = MEDIA_TYPE_RE.match(content_type)

        if matchdata.nil?
          simplified = nil
        else
          media_type = matchdata.captures[0].downcase.gsub(UNREG_RE, '')
          subtype = matchdata.captures[1].downcase.gsub(UNREG_RE, '')
          simplified = "#{media_type}/#{subtype}"
        end
        simplified
      end

      def from_array(*args)
        args = args[0] if args[0].kind_of?(Array)

        m = MIME::TinyType.new(args[0]) { |t| t.extensions  = args[1] if args.size > 1 }

        yield m if
        block_given? ? yield( m ) : m
      end

      def from_hash(hash)
        type = {}
        hash.each_pair do |k, v| 
          type[k.to_s.tr('-A-Z', '_a-z').to_sym] = v
        end

        m = MIME::TinyType.new(type[:content_type]) do |t|
          t.extensions  = type[:extensions]
        end

        block_given? ? yield( m ) : m
      end

      def from_mime_type(mime_type) #:yields the new MIME::TinyType:
        m = MIME::TinyType.new(mime_type.content_type.dup) do |t|
          t.extensions = mime_type.extensions.dup
        end

        yield m if block_given?
      end
    end

    def initialize(content_type)
      matchdata = MEDIA_TYPE_RE.match(content_type)

      if matchdata.nil?
        raise InvalidContentType, "Invalid Content-Type provided ('#{content_type}')"
      end

      @content_type = content_type
      @raw_media_type = matchdata.captures[0]
      @raw_sub_type = matchdata.captures[1]

      @simplified = MIME::TinyType.simplified(@content_type)
      matchdata = MEDIA_TYPE_RE.match(@simplified)
      @media_type = matchdata.captures[0]
      @sub_type = matchdata.captures[1]

      self.extensions   = nil

      yield self if block_given?
    end

    def complete?
      not @extensions.empty?
    end

    def to_s
      @content_type
    end

    def to_str
      @content_type
    end

    def to_a
      [ @content_type, @extensions ]
    end

    def to_hash
      { 'Content-Type'              => @content_type,
        'Extensions'                => @extensions
      }
    end
  end

  # == Usage
  #  require 'tinytypes'
  #
  #  plaintext = MIME::TinyTypes['text/plain']
  #  print plaintext.media_type           # => 'text'
  #  print plaintext.sub_type             # => 'plain'
  #
  #  puts plaintext.extensions.join(" ")  # => 'asc txt c cc h hh cpp'
  #
  #  puts plaintext == 'text/plain'       # => true
  #  puts MIME::TinyType.simplified('x-appl/x-zip') # => 'appl/zip'

  class TinyTypes
    Cdot = '.'.freeze

    def initialize
      @type_variants    = Hash.new { |h, k| h[k] = [] }
      @extension_index  = Hash.new { |h, k| h[k] = [] }
      @simplified_index = {}
    end
    @__types__ = self.new

    def self.types
      @__types__
    end
    
    def add_type_variant(mime_type) #:nodoc:
      @type_variants[mime_type.simplified] << mime_type
    end

    def index_extensions(mime_type) #:nodoc:
      mime_type.extensions.each { |ext| @extension_index[ext] << mime_type }
    end

    def simplified_extensions(mime_type) #:nodoc:
      mime_type.extensions.each { |ext| @simplified_index[ext] ||= mime_type }
    end

    def [](type_id, flags = {})
      if type_id.kind_of?(Regexp)
        matches = []
        @type_variants.each_key do |k|
          matches << @type_variants[k] if k =~ type_id
        end
        matches.flatten!
      elsif type_id.kind_of?(MIME::TinyType)
        matches = [type_id]
      else
        matches = @type_variants[MIME::TinyType.simplified(type_id)]
      end

      matches.delete_if { |e| not e.complete? } if flags[:complete]
      matches.delete_if { |e| not e.platform? } if flags[:platform]
      matches
    end

    def type_for(filename, platform = false)
      #ext = filename.chomp.downcase.gsub(/.*\./o, '')
      pos = filename.rindex(Cdot) # In old rubies, this was faster than the gsub line above.
      ext = pos ? filename[pos+1..-1] : nil
      list = @extension_index[ext]
      list.delete_if { |e| not e.platform? } if platform
      list
    end

    def simple_type_for(filename)
      pos = filename.rindex(Cdot)
      pos ? @simplified_index[filename[pos+1..-1]] : nil
    end

    def of(filename, platform = false)
      type_for(filename, platform)
    end

    class <<self
      def add_type_variant(mime_type)
        @__types__.add_type_variant(mime_type)
      end

      def index_extensions(mime_type)
        @__types__.index_extensions(mime_type)
      end

      def simplified_extensions(mime_type)
	@__types__.simplified_extensions(mime_type)
      end

      def [](type_id, flags = {})
        @__types__[type_id, flags]
      end

      def type_for(filename, platform = false)
        @__types__.type_for(filename, platform)
      end

      def simple_type_for(filename)
	@__types__.simple_type_for(filename)
      end

      def of(filename, platform = false)
        @__types__.type_for(filename, platform)
      end

      def add(*types)
        @__types__.add(*types)
      end
    end
  end
end

data_mime_type = <<MIME_TYPES
!application/xhtml-voice+xml 'DRAFT:draft-mccobb-xplusv-media-type
application/CSTAdata+xml 'IANA,[Ecma International Helpdesk]
application/EDI-Consent 'RFC1767
application/EDI-X12 'RFC1767
application/EDIFACT 'RFC1767
application/activemessage 'IANA,[Shapiro]
application/andrew-inset 'IANA,[Borenstein]
application/applefile :base64 'IANA,[Faltstrom]
application/atom+xml 'RFC4287
application/atomicmail 'IANA,[Borenstein]
application/batch-SMTP 'RFC2442
application/beep+xml 'RFC3080
application/cals-1840 'RFC1895
application/ccxml+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/cnrp+xml 'RFCCNRP
application/commonground 'IANA,[Glazer]
application/conference-info+xml 'DRAFT:draft-ietf-sipping-conference-package
application/cpl+xml 'RFC3880
application/csta+xml 'IANA,[Ecma International Helpdesk]
application/cybercash 'IANA,[Eastlake]
application/dca-rft 'IANA,[Campbell]
application/dec-dx 'IANA,[Campbell]
application/dialog-info+xml 'DRAFT:draft-ietf-sipping-dialog-package
application/dicom 'RFC3240
application/dns 'RFC4027
application/dvcs 'RFC3029
application/ecmascript 'DRAFT:draft-hoehrmann-script-types
application/epp+xml 'RFC3730
application/eshop 'IANA,[Katz]
application/fastinfoset 'IANA,[ITU-T ASN.1 Rapporteur]
application/fastsoap 'IANA,[ITU-T ASN.1 Rapporteur]
application/fits 'RFC4047
application/font-tdpfr @pfr 'RFC3073
application/http 'RFC2616
application/hyperstudio @stk 'IANA,[Domino]
application/iges 'IANA,[Parks]
application/im-iscomposing+xml 'RFC3994
application/index 'RFC2652
application/index.cmd 'RFC2652
application/index.obj 'RFC2652
application/index.response 'RFC2652
application/index.vnd 'RFC2652
application/iotp 'RFC2935
application/ipp 'RFC2910
application/isup 'RFC3204
application/javascript @js :8bit 'DRAFT:draft-hoehrmann-script-types
application/kpml-request+xml 'DRAFT:draft-ietf-sipping-kpml
application/kpml-response+xml 'DRAFT:draft-ietf-sipping-kpml
application/mac-binhex40 @hqx :8bit 'IANA,[Faltstrom]
application/macwriteii 'IANA,[Lindner]
application/marc 'RFC2220
application/mathematica 'IANA,[Van Nostern]
application/mbox 'DRAFT:draft-hall-mime-app-mbox
application/mikey 'RFC3830
application/mp4 'DRAFT:draft-lim-mpeg4-mime
application/mpeg4-generic 'RFC3640
application/mpeg4-iod 'DRAFT:draft-lim-mpeg4-mime
application/mpeg4-iod-xmt 'DRAFT:draft-lim-mpeg4-mime
application/msword @doc,dot :base64 'IANA,[Lindner]
application/news-message-id 'RFC1036,[Spencer]
application/news-transmission 'RFC1036,[Spencer]
application/nss 'IANA,[Hammer]
application/ocsp-request 'RFC2560
application/ocsp-response 'RFC2560
application/octet-stream @bin,dms,lha,lzh,exe,class,ani,pgp :base64 'RFC2045,RFC2046
application/oda @oda 'RFC2045,RFC2046
application/ogg @ogg 'RFC3534
application/parityfec 'RFC3009
application/pdf @pdf :base64 'RFC3778
application/pgp-encrypted :7bit 'RFC3156
application/pgp-keys :7bit 'RFC3156
application/pgp-signature @sig :base64 'RFC3156
application/pidf+xml 'IANA,RFC3863
application/pkcs10 @p10 'RFC2311
application/pkcs7-mime @p7m,p7c 'RFC2311
application/pkcs7-signature @p7s 'RFC2311
application/pkix-cert @cer 'RFC2585
application/pkix-crl @crl 'RFC2585
application/pkix-pkipath @pkipath 'DRAFT:draft-ietf-tls-rfc3546bis
application/pkixcmp @pki 'RFC2510
application/pls+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/poc-settings+xml 'DRAFT:draft-garcia-sipping-poc-isb-am
application/postscript @ai,eps,ps :8bit 'RFC2045,RFC2046
application/prs.alvestrand.titrax-sheet 'IANA,[Alvestrand]
application/prs.cww @cw,cww 'IANA,[Rungchavalnont]
application/prs.nprend @rnd,rct 'IANA,[Doggett]
application/prs.plucker 'IANA,[Janssen]
application/qsig 'RFC3204
application/rdf+xml @rdf 'RFC3870
application/reginfo+xml 'RFC3680
application/remote-printing 'IANA,RFC1486,[Rose]
application/resource-lists+xml 'DRAFT:draft-ietf-simple-xcap-list-usage
application/riscos 'IANA,[Smith]
application/rlmi+xml 'DRAFT:draft-ietf-simple-event-list
application/rls-services+xml 'DRAFT:draft-ietf-simple-xcap-list-usage
application/rtf @rtf 'IANA,[Lindner]
application/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission
application/samlassertion+xml 'IANA,[OASIS Security Services Technical Committee (SSTC)]
application/samlmetadata+xml 'IANA,[OASIS Security Services Technical Committee (SSTC)]
application/sbml+xml 'RFC3823
application/sdp 'RFC2327
application/set-payment 'IANA,[Korver]
application/set-payment-initiation 'IANA,[Korver]
application/set-registration 'IANA,[Korver]
application/set-registration-initiation 'IANA,[Korver]
application/sgml @sgml 'RFC1874
application/sgml-open-catalog @soc 'IANA,[Grosso]
application/shf+xml 'RFC4194
application/sieve @siv 'RFC3028
application/simple-filter+xml 'DRAFT:draft-ietf-simple-filter-format
application/simple-message-summary 'RFC3842
application/slate 'IANA,[Crowley]
application/soap+fastinfoset 'IANA,[ITU-T ASN.1 Rapporteur]
application/soap+xml 'RFC3902
application/spirits-event+xml 'RFC3910
application/srgs 'DRAFT:draft-froumentin-voice-mediatypes
application/srgs+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/ssml+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/timestamp-query 'RFC3161
application/timestamp-reply 'RFC3161
application/tve-trigger 'IANA,[Welsh]
application/vemmi 'RFC2122
application/vnd.3M.Post-it-Notes 'IANA,[O'Brien]
application/vnd.3gpp.pic-bw-large @plb 'IANA,[Meredith]
application/vnd.3gpp.pic-bw-small @psb 'IANA,[Meredith]
application/vnd.3gpp.pic-bw-var @pvb 'IANA,[Meredith]
application/vnd.3gpp.sms @sms 'IANA,[Meredith]
application/vnd.FloGraphIt 'IANA,[Floersch]
application/vnd.Kinar @kne,knp,sdf 'IANA,[Thakkar]
application/vnd.Mobius.DAF 'IANA,[Kabayama]
application/vnd.Mobius.DIS 'IANA,[Kabayama]
application/vnd.Mobius.MBK 'IANA,[Devasia]
application/vnd.Mobius.MQY 'IANA,[Devasia]
application/vnd.Mobius.MSL 'IANA,[Kabayama]
application/vnd.Mobius.PLC 'IANA,[Kabayama]
application/vnd.Mobius.TXF 'IANA,[Kabayama]
application/vnd.Quark.QuarkXPress @qxd,qxt,qwd,qwt,qxl,qxb :8bit 'IANA,[Scheidler]
application/vnd.RenLearn.rlprint 'IANA,[Wick]
application/vnd.accpac.simply.aso 'IANA,[Leow]
application/vnd.accpac.simply.imp 'IANA,[Leow]
application/vnd.acucobol 'IANA,[Lubin]
application/vnd.acucorp @atc,acutc :7bit 'IANA,[Lubin]
application/vnd.adobe.xfdf @xfdf 'IANA,[Perelman]
application/vnd.aether.imp 'IANA,[Moskowitz]
application/vnd.amiga.ami @ami 'IANA,[Blumberg]
application/vnd.apple.installer+xml 'IANA,[Bierman]
application/vnd.audiograph 'IANA,[Slusanschi]
application/vnd.autopackage 'IANA,[Hearn]
application/vnd.blueice.multipass @mpm 'IANA,[Holmstrom]
application/vnd.bmi 'IANA,[Gotoh]
application/vnd.businessobjects 'IANA,[Imoucha]
application/vnd.cinderella @cdy 'IANA,[Kortenkamp]
application/vnd.claymore 'IANA,[Simpson]
application/vnd.commerce-battelle 'IANA,[Applebaum]
application/vnd.commonspace 'IANA,[Chandhok]
application/vnd.contact.cmsg 'IANA,[Patz]
application/vnd.cosmocaller @cmc 'IANA,[Dellutri]
application/vnd.criticaltools.wbs+xml @wbs 'IANA,[Spiller]
application/vnd.ctc-posml 'IANA,[Kohlhepp]
application/vnd.cups-postscript 'IANA,[Sweet]
application/vnd.cups-raster 'IANA,[Sweet]
application/vnd.cups-raw 'IANA,[Sweet]
application/vnd.curl @curl 'IANA,[Byrnes]
application/vnd.cybank 'IANA,[Helmee]
application/vnd.data-vision.rdz @rdz 'IANA,[Fields]
application/vnd.dna 'IANA,[Searcy]
application/vnd.dpgraph 'IANA,[Parker]
application/vnd.dreamfactory @dfac 'IANA,[Appleton]
application/vnd.dxr 'IANA,[Duffy]
application/vnd.ecdis-update 'IANA,[Buettgenbach]
application/vnd.ecowin.chart 'IANA,[Olsson]
application/vnd.ecowin.filerequest 'IANA,[Olsson]
application/vnd.ecowin.fileupdate 'IANA,[Olsson]
application/vnd.ecowin.series 'IANA,[Olsson]
application/vnd.ecowin.seriesrequest 'IANA,[Olsson]
application/vnd.ecowin.seriesupdate 'IANA,[Olsson]
application/vnd.enliven 'IANA,[Santinelli]
application/vnd.epson.esf 'IANA,[Hoshina]
application/vnd.epson.msf 'IANA,[Hoshina]
application/vnd.epson.quickanime 'IANA,[Gu]
application/vnd.epson.salt 'IANA,[Nagatomo]
application/vnd.epson.ssf 'IANA,[Hoshina]
application/vnd.ericsson.quickcall 'IANA,[Tidwell]
application/vnd.eudora.data 'IANA,[Resnick]
application/vnd.fdf 'IANA,[Zilles]
application/vnd.ffsns 'IANA,[Holstage]
application/vnd.fints 'IANA,[Hammann]
application/vnd.fluxtime.clip 'IANA,[Winter]
application/vnd.framemaker 'IANA,[Wexler]
application/vnd.fsc.weblaunch @fsc :7bit 'IANA,[D.Smith]
application/vnd.fujitsu.oasys 'IANA,[Togashi]
application/vnd.fujitsu.oasys2 'IANA,[Togashi]
application/vnd.fujitsu.oasys3 'IANA,[Okudaira]
application/vnd.fujitsu.oasysgp 'IANA,[Sugimoto]
application/vnd.fujitsu.oasysprs 'IANA,[Ogita]
application/vnd.fujixerox.ddd 'IANA,[Onda]
application/vnd.fujixerox.docuworks 'IANA,[Taguchi]
application/vnd.fujixerox.docuworks.binder 'IANA,[Matsumoto]
application/vnd.fut-misnet 'IANA,[Pruulmann]
application/vnd.genomatix.tuxedo @txd 'IANA,[Frey]
application/vnd.grafeq 'IANA,[Tupper]
application/vnd.groove-account 'IANA,[Joseph]
application/vnd.groove-help 'IANA,[Joseph]
application/vnd.groove-identity-message 'IANA,[Joseph]
application/vnd.groove-injector 'IANA,[Joseph]
application/vnd.groove-tool-message 'IANA,[Joseph]
application/vnd.groove-tool-template 'IANA,[Joseph]
application/vnd.groove-vcard 'IANA,[Joseph]
application/vnd.hbci @hbci,hbc,kom,upa,pkd,bpd 'IANA,[Hammann]
application/vnd.hcl-bireports 'IANA,[Serres]
application/vnd.hhe.lesson-player @les 'IANA,[Jones]
application/vnd.hp-HPGL @plt,hpgl 'IANA,[Pentecost]
application/vnd.hp-PCL 'IANA,[Pentecost]
application/vnd.hp-PCLXL 'IANA,[Pentecost]
application/vnd.hp-hpid 'IANA,[Gupta]
application/vnd.hp-hps 'IANA,[Aubrey]
application/vnd.httphone 'IANA,[Lefevre]
application/vnd.hzn-3d-crossword 'IANA,[Minnis]
application/vnd.ibm.MiniPay 'IANA,[Herzberg]
application/vnd.ibm.afplinedata 'IANA,[Buis]
application/vnd.ibm.electronic-media @emm 'IANA,[Tantlinger]
application/vnd.ibm.modcap 'IANA,[Hohensee]
application/vnd.ibm.rights-management @irm 'IANA,[Tantlinger]
application/vnd.ibm.secure-container @sc 'IANA,[Tantlinger]
application/vnd.informix-visionary 'IANA,[Gales]
application/vnd.intercon.formnet 'IANA,[Gurak]
application/vnd.intertrust.digibox 'IANA,[Tomasello]
application/vnd.intertrust.nncp 'IANA,[Tomasello]
application/vnd.intu.qbo 'IANA,[Scratchley]
application/vnd.intu.qfx 'IANA,[Scratchley]
application/vnd.ipunplugged.rcprofile @rcprofile 'IANA,[Ersson]
application/vnd.irepository.package+xml @irp 'IANA,[Knowles]
application/vnd.is-xpr 'IANA,[Natarajan]
application/vnd.japannet-directory-service 'IANA,[Fujii]
application/vnd.japannet-jpnstore-wakeup 'IANA,[Yoshitake]
application/vnd.japannet-payment-wakeup 'IANA,[Fujii]
application/vnd.japannet-registration 'IANA,[Yoshitake]
application/vnd.japannet-registration-wakeup 'IANA,[Fujii]
application/vnd.japannet-setstore-wakeup 'IANA,[Yoshitake]
application/vnd.japannet-verification 'IANA,[Yoshitake]
application/vnd.japannet-verification-wakeup 'IANA,[Fujii]
application/vnd.jisp @jisp 'IANA,[Deckers]
application/vnd.kahootz 'IANA,[Macdonald]
application/vnd.kde.karbon @karbon 'IANA,[Faure]
application/vnd.kde.kchart @chrt 'IANA,[Faure]
application/vnd.kde.kformula @kfo 'IANA,[Faure]
application/vnd.kde.kivio @flw 'IANA,[Faure]
application/vnd.kde.kontour @kon 'IANA,[Faure]
application/vnd.kde.kpresenter @kpr,kpt 'IANA,[Faure]
application/vnd.kde.kspread @ksp 'IANA,[Faure]
application/vnd.kde.kword @kwd,kwt 'IANA,[Faure]
application/vnd.kenameaapp @htke 'IANA,[DiGiorgio-Haag]
application/vnd.kidspiration @kia 'IANA,[Bennett]
application/vnd.koan 'IANA,[Cole]
application/vnd.liberty-request+xml 'IANA,[McDowell]
application/vnd.llamagraphics.life-balance.desktop @lbd 'IANA,[White]
application/vnd.llamagraphics.life-balance.exchange+xml @lbe 'IANA,[White]
application/vnd.lotus-1-2-3 @wks,123 'IANA,[Wattenberger]
application/vnd.lotus-approach 'IANA,[Wattenberger]
application/vnd.lotus-freelance 'IANA,[Wattenberger]
application/vnd.lotus-notes 'IANA,[Laramie]
application/vnd.lotus-organizer 'IANA,[Wattenberger]
application/vnd.lotus-screencam 'IANA,[Wattenberger]
application/vnd.lotus-wordpro 'IANA,[Wattenberger]
application/vnd.marlin.drm.mdcf 'IANA,[Ellison]
application/vnd.mcd @mcd 'IANA,[Gotoh]
application/vnd.mediastation.cdkey 'IANA,[Flurry]
application/vnd.meridian-slingshot 'IANA,[Wedel]
application/vnd.mfmp @mfm 'IANA,[Ikeda]
application/vnd.micrografx.flo @flo 'IANA,[Prevo]
application/vnd.micrografx.igx @igx 'IANA,[Prevo]
application/vnd.mif @mif 'IANA,[Wexler]
application/vnd.minisoft-hp3000-save 'IANA,[Bartram]
application/vnd.mitsubishi.misty-guard.trustweb 'IANA,[Tanaka]
application/vnd.mophun.application @mpn 'IANA,[Wennerstrom]
application/vnd.mophun.certificate @mpc 'IANA,[Wennerstrom]
application/vnd.motorola.flexsuite 'IANA,[Patton]
application/vnd.motorola.flexsuite.adsi 'IANA,[Patton]
application/vnd.motorola.flexsuite.fis 'IANA,[Patton]
application/vnd.motorola.flexsuite.gotap 'IANA,[Patton]
application/vnd.motorola.flexsuite.kmr 'IANA,[Patton]
application/vnd.motorola.flexsuite.ttc 'IANA,[Patton]
application/vnd.motorola.flexsuite.wem 'IANA,[Patton]
application/vnd.mozilla.xul+xml @xul 'IANA,[McDaniel]
application/vnd.ms-artgalry @cil 'IANA,[Slawson]
application/vnd.ms-asf @asf 'IANA,[Fleischman]
application/vnd.ms-cab-compressed @cab 'IANA,[Scarborough]
application/vnd.ms-excel @xls,xlt :base64 'IANA,[Gill]
application/vnd.ms-fontobject 'IANA,[Scarborough]
application/vnd.ms-ims 'IANA,[Ledoux]
application/vnd.ms-lrm @lrm 'IANA,[Ledoux]
application/vnd.ms-powerpoint @ppt,pps,pot :base64 'IANA,[Gill]
application/vnd.ms-project @mpp :base64 'IANA,[Gill]
application/vnd.ms-tnef :base64 'IANA,[Gill]
application/vnd.ms-works :base64 'IANA,[Gill]
application/vnd.ms-wpl @wpl :base64 'IANA,[Plastina]
application/vnd.mseq @mseq 'IANA,[Le Bodic]
application/vnd.msign 'IANA,[Borcherding]
application/vnd.music-niff 'IANA,[Butler]
application/vnd.musician 'IANA,[Adams]
application/vnd.nervana @ent,entity,req,request,bkm,kcm 'IANA,[Judkins]
application/vnd.netfpx 'IANA,[Mutz]
application/vnd.noblenet-directory 'IANA,[Solomon]
application/vnd.noblenet-sealer 'IANA,[Solomon]
application/vnd.noblenet-web 'IANA,[Solomon]
application/vnd.nokia.landmark+wbxml 'IANA,[Nokia]
application/vnd.nokia.landmark+xml 'IANA,[Nokia]
application/vnd.nokia.landmarkcollection+xml 'IANA,[Nokia]
application/vnd.nokia.radio-preset @rpst 'IANA,[Nokia]
application/vnd.nokia.radio-presets @rpss 'IANA,[Nokia]
application/vnd.novadigm.EDM 'IANA,[Swenson]
application/vnd.novadigm.EDX 'IANA,[Swenson]
application/vnd.novadigm.EXT 'IANA,[Swenson]
application/vnd.obn 'IANA,[Hessling]
application/vnd.omads-email+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.omads-file+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.omads-folder+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.osa.netdeploy 'IANA,[Klos]
application/vnd.osgi.dp 'IANA,[Kriens]
application/vnd.palm @prc,pdb,pqa,oprc :base64 'IANA,[Peacock]
application/vnd.paos.xml 'IANA,[Kemp]
application/vnd.pg.format 'IANA,[Gandert]
application/vnd.pg.osasli 'IANA,[Gandert]
application/vnd.piaccess.application-licence 'IANA,[Maneos]
application/vnd.picsel @efif 'IANA,[Naccarato]
application/vnd.powerbuilder6 'IANA,[Guy]
application/vnd.powerbuilder6-s 'IANA,[Guy]
application/vnd.powerbuilder7 'IANA,[Shilts]
application/vnd.powerbuilder7-s 'IANA,[Shilts]
application/vnd.powerbuilder75 'IANA,[Shilts]
application/vnd.powerbuilder75-s 'IANA,[Shilts]
application/vnd.preminet 'IANA,[Tenhunen]
application/vnd.previewsystems.box 'IANA,[Smolgovsky]
application/vnd.proteus.magazine 'IANA,[Hoch]
application/vnd.publishare-delta-tree 'IANA,[Ben-Kiki]
application/vnd.pvi.ptid1 @pti,ptid 'IANA,[Lamb]
application/vnd.pwg-multiplexed 'RFC3391
application/vnd.pwg-xhtml-print+xml 'IANA,[Wright]
application/vnd.rapid 'IANA,[Szekely]
application/vnd.ruckus.download 'IANA,[Harris]
application/vnd.s3sms 'IANA,[Tarkkala]
application/vnd.sealed.doc @sdoc,sdo,s1w 'IANA,[Petersen]
application/vnd.sealed.eml @seml,sem 'IANA,[Petersen]
application/vnd.sealed.mht @smht,smh 'IANA,[Petersen]
application/vnd.sealed.net 'IANA,[Lambert]
application/vnd.sealed.ppt @sppt,spp,s1p 'IANA,[Petersen]
application/vnd.sealed.xls @sxls,sxl,s1e 'IANA,[Petersen]
application/vnd.sealedmedia.softseal.html @stml,stm,s1h 'IANA,[Petersen]
application/vnd.sealedmedia.softseal.pdf @spdf,spd,s1a 'IANA,[Petersen]
application/vnd.seemail @see 'IANA,[Webb]
application/vnd.sema 'IANA,[Hansson]
application/vnd.shana.informed.formdata 'IANA,[Selzler]
application/vnd.shana.informed.formtemplate 'IANA,[Selzler]
application/vnd.shana.informed.interchange 'IANA,[Selzler]
application/vnd.shana.informed.package 'IANA,[Selzler]
application/vnd.smaf @mmf 'IANA,[Takahashi]
application/vnd.sss-cod 'IANA,[Dani]
application/vnd.sss-dtf 'IANA,[Bruno]
application/vnd.sss-ntf 'IANA,[Bruno]
application/vnd.street-stream 'IANA,[Levitt]
application/vnd.sus-calendar @sus,susp 'IANA,[Niedfeldt]
application/vnd.svd 'IANA,[Becker]
application/vnd.swiftview-ics 'IANA,[Widener]
application/vnd.syncml.+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.syncml.ds.notification 'IANA,[OMA Data Synchronization Working Group]
application/vnd.triscape.mxs 'IANA,[Simonoff]
application/vnd.trueapp 'IANA,[Hepler]
application/vnd.truedoc 'IANA,[Chase]
application/vnd.ufdl 'IANA,[Manning]
application/vnd.uiq.theme 'IANA,[Ocock]
application/vnd.uplanet.alert 'IANA,[Martin]
application/vnd.uplanet.alert-wbxml 'IANA,[Martin]
application/vnd.uplanet.bearer-choice 'IANA,[Martin]
application/vnd.uplanet.bearer-choice-wbxml 'IANA,[Martin]
application/vnd.uplanet.cacheop 'IANA,[Martin]
application/vnd.uplanet.cacheop-wbxml 'IANA,[Martin]
application/vnd.uplanet.channel 'IANA,[Martin]
application/vnd.uplanet.channel-wbxml 'IANA,[Martin]
application/vnd.uplanet.list 'IANA,[Martin]
application/vnd.uplanet.list-wbxml 'IANA,[Martin]
application/vnd.uplanet.listcmd 'IANA,[Martin]
application/vnd.uplanet.listcmd-wbxml 'IANA,[Martin]
application/vnd.uplanet.signal 'IANA,[Martin]
application/vnd.vcx 'IANA,[T.Sugimoto]
application/vnd.vectorworks 'IANA,[Pharr]
application/vnd.vidsoft.vidconference @vsc :8bit 'IANA,[Hess]
application/vnd.visio @vsd,vst,vsw,vss 'IANA,[Sandal]
application/vnd.visionary @vis 'IANA,[Aravindakumar]
application/vnd.vividence.scriptfile 'IANA,[Risher]
application/vnd.vsf 'IANA,[Rowe]
application/vnd.wap.sic @sic 'IANA,[WAP-Forum]
application/vnd.wap.slc @slc 'IANA,[WAP-Forum]
application/vnd.wap.wbxml @wbxml 'IANA,[Stark]
application/vnd.wap.wmlc @wmlc 'IANA,[Stark]
application/vnd.wap.wmlscriptc @wmlsc 'IANA,[Stark]
application/vnd.webturbo @wtb 'IANA,[Rehem]
application/vnd.wordperfect @wpd 'IANA,[Scarborough]
application/vnd.wqd @wqd 'IANA,[Bostrom]
application/vnd.wrq-hp3000-labelled 'IANA,[Bartram]
application/vnd.wt.stf 'IANA,[Wohler]
application/vnd.wv.csp+wbxml @wv 'IANA,[Salmi]
application/vnd.wv.csp+xml :8bit 'IANA,[Ingimundarson]
application/vnd.wv.ssp+xml :8bit 'IANA,[Ingimundarson]
application/vnd.xara 'IANA,[Matthewman]
application/vnd.xfdl 'IANA,[Manning]
application/vnd.yamaha.hv-dic @hvd 'IANA,[Yamamoto]
application/vnd.yamaha.hv-script @hvs 'IANA,[Yamamoto]
application/vnd.yamaha.hv-voice @hvp 'IANA,[Yamamoto]
application/vnd.yamaha.smaf-audio @saf 'IANA,[Shinoda]
application/vnd.yamaha.smaf-phrase @spf 'IANA,[Shinoda]
application/vnd.yellowriver-custom-menu 'IANA,[Yellow]
application/vnd.zzazz.deck+xml 'IANA,[Hewett]
application/voicexml+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/watcherinfo+xml @wif 'RFC3858
application/whoispp-query 'RFC2957
application/whoispp-response 'RFC2958
application/wita 'IANA,[Campbell]
application/wordperfect5.1 @wp5,wp 'IANA,[Lindner]
application/x400-bp 'RFC1494
application/xcap-att+xml 'DRAFT:draft-ietf-simple-xcap
application/xcap-caps+xml 'DRAFT:draft-ietf-simple-xcap
application/xcap-el+xml 'DRAFT:draft-ietf-simple-xcap
application/xcap-error+xml 'DRAFT:draft-ietf-simple-xcap
application/xhtml+xml @xhtml :8bit 'RFC3236
application/xml @xml :8bit 'RFC3023
application/xml-dtd :8bit 'RFC3023
application/xml-external-parsed-entity 'RFC3023
application/xmpp+xml 'RFC3923
application/xop+xml 'IANA,[Nottingham]
application/xv+xml 'DRAFT:draft-mccobb-xv-media-type
application/zip @zip :base64 'IANA,[Lindner]

  # Registered: audio/*
!audio/vnd.qcelp 'IANA,RFC3625 =use-instead:audio/QCELP
audio/32kadpcm 'RFC2421,RFC2422
audio/3gpp @3gpp 'RFC3839,DRAFT:draft-gellens-bucket
audio/3gpp2 'DRAFT:draft-garudadri-avt-3gpp2-mime
audio/AMR @amr :base64 'RFC3267
audio/AMR-WB @awb :base64 'RFC3267
audio/BV16 'RFC4298
audio/BV32 'RFC4298
audio/CN 'RFC3389
audio/DAT12 'RFC3190
audio/DVI4 'RFC3555
audio/EVRC @evc 'RFC3558
audio/EVRC-QCP 'RFC3625
audio/EVRC0 'RFC3558
audio/G722 'RFC3555
audio/G7221 'RFC3047
audio/G723 'RFC3555
audio/G726-16 'RFC3555
audio/G726-24 'RFC3555
audio/G726-32 'RFC3555
audio/G726-40 'RFC3555
audio/G728 'RFC3555
audio/G729 'RFC3555
audio/G729D 'RFC3555
audio/G729E 'RFC3555
audio/GSM 'RFC3555
audio/GSM-EFR 'RFC3555
audio/L16 @l16 'RFC3555
audio/L20 'RFC3190
audio/L24 'RFC3190
audio/L8 'RFC3555
audio/LPC 'RFC3555
audio/MP4A-LATM 'RFC3016
audio/MPA 'RFC3555
audio/PCMA 'RFC3555
audio/PCMU 'RFC3555
audio/QCELP @qcp 'RFC3555'RFC3625
audio/RED 'RFC3555
audio/SMV @smv 'RFC3558
audio/SMV-QCP 'RFC3625
audio/SMV0 'RFC3558
audio/VDVI 'RFC3555
audio/VMR-WB 'DRAFT:draft-ietf-avt-rtp-vmr-wb,DRAFT:draft-ietf-avt-rtp-vmr-wb-extension
audio/ac3 'RFC4184
audio/amr-wb+ 'DRAFT:draft-ietf-avt-rtp-amrwbplus
audio/basic @au,snd :base64 'RFC2045,RFC2046
audio/clearmode 'RFC4040
audio/dsr-es201108 'RFC3557
audio/dsr-es202050 'RFC4060
audio/dsr-es202211 'RFC4060
audio/dsr-es202212 'RFC4060
audio/iLBC 'RFC3952
audio/mp4 'DRAFT:draft-lim-mpeg4-mime
audio/mpa-robust 'RFC3119
audio/mpeg @mpga,mp2,mp3 :base64 'RFC3003
audio/mpeg4-generic 'RFC3640
audio/parityfec 'RFC3009
audio/prs.sid @sid,psid 'IANA,[Walleij]
audio/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission
audio/t140c 'DRAFT:draft-ietf-avt-audio-t140c
audio/telephone-event 'RFC2833
audio/tone 'RFC2833
audio/vnd.3gpp.iufp 'IANA,[Belling]
audio/vnd.audiokoz 'IANA,[DeBarros]
audio/vnd.cisco.nse 'IANA,[Kumar]
audio/vnd.cmles.radio-events 'IANA,[Goulet]
audio/vnd.cns.anp1 'IANA,[McLaughlin]
audio/vnd.cns.inf1 'IANA,[McLaughlin]
audio/vnd.digital-winds @eol :7bit 'IANA,[Strazds]
audio/vnd.dlna.adts 'IANA,[Heredia]
audio/vnd.everad.plj @plj 'IANA,[Cicelsky]
audio/vnd.lucent.voice @lvp 'IANA,[Vaudreuil]
audio/vnd.nokia.mobile-xmf @mxmf 'IANA,[Nokia Corporation]
audio/vnd.nortel.vbk @vbk 'IANA,[Parsons]
audio/vnd.nuera.ecelp4800 @ecelp4800 'IANA,[Fox]
audio/vnd.nuera.ecelp7470 @ecelp7470 'IANA,[Fox]
audio/vnd.nuera.ecelp9600 @ecelp9600 'IANA,[Fox]
audio/vnd.octel.sbc 'IANA,[Vaudreuil]
audio/vnd.rhetorex.32kadpcm 'IANA,[Vaudreuil]
audio/vnd.sealedmedia.softseal.mpeg @smp3,smp,s1m 'IANA,[Petersen]
audio/vnd.vmx.cvsd 'IANA,[Vaudreuil]

  # Registered: image/*
image/cgm 'IANA =Computer Graphics Metafile [Francis]
image/fits 'RFC4047
image/g3fax 'RFC1494
image/gif @gif :base64 'RFC2045,RFC2046
image/ief @ief :base64 'RFC1314 =Image Exchange Format
image/jp2 @jp2 :base64 'IANA,RFC3745
image/jpeg @jpeg,jpg,jpe :base64 'RFC2045,RFC2046
image/jpm @jpm :base64 'IANA,RFC3745
image/jpx @jpx :base64 'IANA,RFC3745
image/naplps 'IANA,[Ferber]
image/png @png :base64 'IANA,[Randers-Pehrson]
image/prs.btif 'IANA,[Simon]
image/prs.pti 'IANA,[Laun]
image/t38 'RFC3362
image/tiff @tiff,tif :base64 'RFC3302 =Tag Image File Format
image/tiff-fx 'RFC3950 =Tag Image File Format Fax eXtended
image/vnd.adobe.photoshop 'IANA,[Scarborough]
image/vnd.cns.inf2 'IANA,[McLaughlin]
image/vnd.djvu @djvu,djv 'IANA,[Bottou]
image/vnd.dwg @dwg 'IANA,[Moline]
image/vnd.dxf 'IANA,[Moline]
image/vnd.fastbidsheet 'IANA,[Becker]
image/vnd.fpx 'IANA,[Spencer]
image/vnd.fst 'IANA,[Fuldseth]
image/vnd.fujixerox.edmics-mmr 'IANA,[Onda]
image/vnd.fujixerox.edmics-rlc 'IANA,[Onda]
image/vnd.globalgraphics.pgb @pgb 'IANA,[Bailey]
image/vnd.microsoft.icon @ico 'IANA,[Butcher]
image/vnd.mix 'IANA,[Reddy]
image/vnd.ms-modi @mdi 'IANA,[Vaughan]
image/vnd.net-fpx 'IANA,[Spencer]
image/vnd.sealed.png @spng,spn,s1n 'IANA,[Petersen]
image/vnd.sealedmedia.softseal.gif @sgif,sgi,s1g 'IANA,[Petersen]
image/vnd.sealedmedia.softseal.jpg @sjpg,sjp,s1j 'IANA,[Petersen]
image/vnd.svf 'IANA,[Moline]
image/vnd.wap.wbmp @wbmp 'IANA,[Stark]
image/vnd.xiff 'IANA,[S.Martin]

  # Registered: message/*
message/CPIM 'RFC3862
message/delivery-status 'RFC1894
message/disposition-notification 'RFC2298
message/external-body :8bit 'RFC2046
message/http 'RFC2616
message/news :8bit 'RFC1036,[H.Spencer]
message/partial :8bit 'RFC2046
message/rfc822 :8bit 'RFC2046
message/s-http 'RFC2660
message/sip 'RFC3261
message/sipfrag 'RFC3420
message/tracking-status 'RFC3886

  # Registered: model/*
model/iges @igs,iges 'IANA,[Parks]
model/mesh @msh,mesh,silo 'RFC2077
model/vnd.dwf 'IANA,[Pratt]
model/vnd.flatland.3dml 'IANA,[Powers]
model/vnd.gdl 'IANA,[Babits]
model/vnd.gs-gdl 'IANA,[Babits]
model/vnd.gtw 'IANA,[Ozaki]
model/vnd.mts 'IANA,[Rabinovitch]
model/vnd.parasolid.transmit.binary @x_b,xmt_bin 'IANA,[Parasolid]
model/vnd.parasolid.transmit.text @x_t,xmt_txt :quoted-printable 'IANA,[Parasolid]
model/vnd.vtu 'IANA,[Rabinovitch]
model/vrml @wrl,vrml 'RFC2077

  # Registered: multipart/*
multipart/alternative :8bit 'RFC2045,RFC2046
multipart/appledouble :8bit 'IANA,[Faltstrom]
multipart/byteranges 'RFC2068
multipart/digest :8bit 'RFC2045,RFC2046
multipart/encrypted 'RFC1847
multipart/form-data 'RFC2388
multipart/header-set 'IANA,[Crocker]
multipart/mixed :8bit 'RFC2045,RFC2046
multipart/parallel :8bit 'RFC2045,RFC2046
multipart/related 'RFC2387
multipart/report 'RFC1892
multipart/signed 'RFC1847
multipart/voice-message 'RFC2421,RFC2423

  # Registered: text/*
!text/ecmascript 'DRAFT:draft-hoehrmann-script-types
!text/javascript 'DRAFT:draft-hoehrmann-script-types
text/calendar 'RFC2445
text/css @css :8bit 'RFC2318
text/csv @csv :8bit 'RFC4180
text/directory 'RFC2425
text/dns 'RFC4027
text/enriched 'RFC1896
text/html @html,htm,htmlx,shtml,htx :8bit 'RFC2854
text/parityfec 'RFC3009
text/plain @txt,asc,c,cc,h,hh,cpp,hpp,dat,hlp 'RFC2046,RFC3676
text/prs.fallenstein.rst @rst 'IANA,[Fallenstein]
text/prs.lines.tag 'IANA,[Lines]
text/RED 'RFC4102
text/rfc822-headers 'RFC1892
text/richtext @rtx :8bit 'RFC2045,RFC2046
text/rtf @rtf :8bit 'IANA,[Lindner]
text/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission
text/sgml @sgml,sgm 'RFC1874
text/t140 'RFC4103
text/tab-separated-values @tsv 'IANA,[Lindner]
text/troff @t,tr,roff,troff :8bit 'DRAFT:draft-lilly-text-troff
text/uri-list 'RFC2483
text/vnd.abc 'IANA,[Allen]
text/vnd.curl 'IANA,[Byrnes]
text/vnd.DMClientScript 'IANA,[Bradley]
text/vnd.esmertec.theme-descriptor 'IANA,[Eilemann]
text/vnd.fly 'IANA,[Gurney]
text/vnd.fmi.flexstor 'IANA,[Hurtta]
text/vnd.in3d.3dml 'IANA,[Powers]
text/vnd.in3d.spot 'IANA,[Powers]
text/vnd.IPTC.NewsML '[IPTC]
text/vnd.IPTC.NITF '[IPTC]
text/vnd.latex-z 'IANA,[Lubos]
text/vnd.motorola.reflex 'IANA,[Patton]
text/vnd.ms-mediapackage 'IANA,[Nelson]
text/vnd.net2phone.commcenter.command @ccc 'IANA,[Xie]
text/vnd.sun.j2me.app-descriptor @jad :8bit 'IANA,[G.Adams]
text/vnd.wap.si @si 'IANA,[WAP-Forum]
text/vnd.wap.sl @sl 'IANA,[WAP-Forum]
text/vnd.wap.wml @wml 'IANA,[Stark]
text/vnd.wap.wmlscript @wmls 'IANA,[Stark]
text/xml @xml,dtd :8bit 'RFC3023
text/xml-external-parsed-entity 'RFC3023
vms:text/plain @doc :8bit

  # Registered: video/*
video/3gpp @3gp,3gpp 'RFC3839,DRAFT:draft-gellens-mime-bucket 
video/3gpp-tt 'DRAFT:draft-ietf-avt-rtp-3gpp-timed-text 
video/3gpp2 'DRAFT:draft-garudadri-avt-3gpp2-mime 
video/BMPEG 'RFC3555 
video/BT656 'RFC3555 
video/CelB 'RFC3555 
video/DV 'RFC3189 
video/H261 'RFC3555 
video/H263 'RFC3555 
video/H263-1998 'RFC3555 
video/H263-2000 'RFC3555 
video/H264 'RFC3984 
video/JPEG 'RFC3555 
video/MJ2 @mj2,mjp2 'RFC3745 
video/MP1S 'RFC3555 
video/MP2P 'RFC3555 
video/MP2T 'RFC3555 
video/mp4 'DRAFT:draft-lim-mpeg4-mime 
video/MP4V-ES 'RFC3016 
video/mpeg @mp2,mpe,mp3g,mpg :base64 'RFC2045,RFC2046 
video/mpeg4-generic 'RFC3640 
video/MPV 'RFC3555 
video/nv 'RFC3555 
video/parityfec 'RFC3009 
video/pointer 'RFC2862 
video/quicktime @qt,mov :base64 'IANA,[Lindner] 
video/raw 'RFC4175 
video/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission 
video/SMPTE292M 'RFC3497 
video/vnd.dlna.mpeg-tts 'IANA,[Heredia] 
video/vnd.fvt 'IANA,[Fuldseth] 
video/vnd.motorola.video 'IANA,[McGinty] 
video/vnd.motorola.videop 'IANA,[McGinty] 
video/vnd.mpegurl @mxu,m4u :8bit 'IANA,[Recktenwald] 
video/vnd.nokia.interleaved-multimedia @nim 'IANA,[Kangaslampi] 
video/vnd.objectvideo @mp4 'IANA,[Clark] 
video/vnd.sealed.mpeg1 @s11 'IANA,[Petersen] 
video/vnd.sealed.mpeg4 @smpg,s14 'IANA,[Petersen] 
video/vnd.sealed.swf @sswf,ssw 'IANA,[Petersen] 
video/vnd.sealedmedia.softseal.mov @smov,smo,s1q 'IANA,[Petersen] 
video/vnd.vivo @viv,vivo 'IANA,[Wolfe] 

  # Unregistered: application/*
!application/x-troff 'LTSW =use-instead:text/troff
application/x-bcpio @bcpio 'LTSW
application/x-compressed @z,Z :base64 'LTSW
application/x-cpio @cpio :base64 'LTSW
application/x-csh @csh :8bit 'LTSW
application/x-dvi @dvi :base64 'LTSW
application/x-gtar @gtar,tgz,tbz2,tbz :base64 'LTSW
application/x-gzip @gz :base64 'LTSW
application/x-hdf @hdf 'LTSW
application/x-java-archive @jar 'LTSW
application/x-java-jnlp-file @jnlp 'LTSW
application/x-java-serialized-object @ser 'LTSW
application/x-java-vm @class 'LTSW
application/x-latex @ltx,latex :8bit 'LTSW
application/x-mif @mif 'LTSW
application/x-rtf 'LTSW =use-instead:application/rtf
application/x-sh @sh 'LTSW
application/x-shar @shar 'LTSW
application/x-stuffit @sit :base64 'LTSW
application/x-sv4cpio @sv4cpio :base64 'LTSW
application/x-sv4crc @sv4crc :base64 'LTSW
application/x-tar @tar :base64 'LTSW
application/x-tcl @tcl :8bit 'LTSW
application/x-tex @tex :8bit
application/x-texinfo @texinfo,texi :8bit
application/x-troff-man @man :8bit 'LTSW
application/x-troff-me @me 'LTSW
application/x-troff-ms @ms 'LTSW
application/x-ustar @ustar :base64 'LTSW
application/x-wais-source @src 'LTSW
mac:application/x-mac @bin :base64
*!application/cals1840 'LTSW =use-instead:application/cals-1840
*!application/remote_printing 'LTSW =use-instead:application/remote-printing
*!application/x-u-star 'LTSW =use-instead:application/x-ustar
*!application/x400.bp 'LTSW =use-instead:application/x400-bp
*application/acad 'LTSW
*application/clariscad 'LTSW
*application/drafting 'LTSW
*application/dxf 'LTSW
*application/excel @xls,xlt 'LTSW
*application/fractals 'LTSW
*application/i-deas 'LTSW
*application/macbinary 'LTSW
*application/netcdf @nc,cdf 'LTSW
*application/powerpoint @ppt,pps,pot :base64 'LTSW
*application/pro_eng 'LTSW
*application/set 'LTSW
*application/SLA 'LTSW
*application/solids 'LTSW
*application/STEP 'LTSW
*application/vda 'LTSW
*application/word @doc,dot 'LTSW

  # Unregistered: audio/*
audio/x-aiff @aif,aifc,aiff :base64
audio/x-midi @mid,midi,kar :base64
audio/x-pn-realaudio @rm,ram :base64
audio/x-pn-realaudio-plugin @rpm
audio/x-realaudio @ra :base64
audio/x-wav @wav :base64

  # Unregistered: image/*
*image/vnd.dgn @dgn =use-instead:image/x-vnd.dgn
image/x-bmp @bmp
image/x-cmu-raster @ras
image/x-paintshoppro @psp,pspimage :base64
image/x-pict
image/x-portable-anymap @pnm :base64
image/x-portable-bitmap @pbm :base64
image/x-portable-graymap @pgm :base64
image/x-portable-pixmap @ppm :base64
image/x-rgb @rgb :base64
image/x-targa @tga
image/x-vnd.dgn @dgn
image/x-win-bmp
image/x-xbitmap @xbm :7bit
image/x-xbm @xbm :7bit
image/x-xpixmap @xpm :8bit
image/x-xwindowdump @xwd :base64
*!image/cmu-raster =use-instead:image/x-cmu-raster
*!image/vnd.net.fpx =use-instead:image/vnd.net-fpx
*image/bmp @bmp
*image/targa @tga

  # Unregistered: multipart/*
multipart/x-gzip
multipart/x-mixed-replace
multipart/x-tar
multipart/x-ustar
multipart/x-www-form-urlencoded
multipart/x-zip
*!multipart/parallel =use-instead:multipart/parallel

  # Unregistered: text/*
*text/comma-separated-values @csv :8bit
*text/vnd.flatland.3dml =use-instead:model/vnd.flatland.3dml
text/x-vnd.flatland.3dml =use-instead:model/vnd.flatland.3dml
text/x-setext @etx
text/x-vcalendar @vcs :8bit
text/x-vcard @vcf :8bit
text/x-yaml @yaml,yml :8bit

  # Unregistered: video/*
*video/dl @dl :base64
*video/gl @gl :base64
video/x-msvideo @avi :base64
video/x-sgi-movie @movie :base64

  # Unregistered: other/*
x-chemical/x-pdb @pdb
x-chemical/x-xyz @xyz
x-conference/x-cooltalk @ice
x-drawing/dwf @dwf
x-world/x-vrml @wrl,vrml
MIME_TYPES

_re = %r{
  ^
  ([*])?                                # 0: Unregistered?
  (!)?                                  # 1: Obsolete?
  (?:(\w+):)?                           # 2: Platform marker
  #{MIME::TinyType::MEDIA_TYPE_RE}          # 3,4: Media type
  (?:\s@([^\s]+))?                      # 5: Extensions
  (?:\s:(#{MIME::TinyType::ENCODING_RE}))?  # 6: Encoding
  (?:\s'(.+))?                          # 7: URL list
  (?:\s=(.+))?                          # 8: Documentation
  $
}x

data_mime_type.each_line do |i|
  item = i.chomp.strip.gsub(%r{#.*}o, '')
  next if item.empty?

  m = _re.match(item).captures

  unregistered,
  obsolete,
  platform,
  mediatype,
  subtype,
  extensions,
  encoding,
  urls,
  docs = *m

  extensions &&= extensions.split(/,/)
  urls &&= urls.split(/,/)

  mime_type = MIME::TinyType.new("#{mediatype}/#{subtype}") do |t|
    t.extensions  = extensions
  end

  MIME::TinyTypes.add_type_variant(mime_type)
  MIME::TinyTypes.index_extensions(mime_type)
  MIME::TinyTypes.simplified_extensions(mime_type)
end

_re             = nil
data_mime_type  = nil
