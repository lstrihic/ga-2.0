---
date: 2026-09-17
researcher: Codex
topic: "Coral AI SRE: portanje Tracka na Labs 2.0 kroz CLI i HCL"
project: labs-2-ga-coral-ai-sre
status: "Istraživanje i prijedlog porta; port još nije implementiran ni testiran uživo"
tags: [instruqt, labs, hcl, migration, coral, ga-testing]
source_revisions:
  go-cli: e3774cd9f9b46bdccb6b7dc0b5a9f2d7b93a3a76
  mono: 3e87e7e18ba279a3df0141056ef94173a27bde15
  lab-sdk: dec5f09bc7441073e74162e8dbd630ba3ebfe7a3
---

# Coral AI SRE — Track → Labs 2.0

## 1. Svrha i granice

Zahtjev: „bravo. mozes to zapisat u markdown file sto pronades u route koje su razlike tracka i labsa i kako ih portati svaki dio“

Ovo je radni vodič za portanje originalnog tracka **AI SRE: Root-Cause an Incident with One SQL Query**, `jparton-challenge/coral-ai-sre`, kroz **CLI + HCL**. Pokriva postojeću infrastrukturu, svih pet challengea, skripte, upute, tabove, AWS, datoteke i provjeru rezultata.

**Originalni track ne mijenjamo — ni na platformi ni u lokalnom `track/` folderu.** Promjene budućeg porta rade se isključivo u `lab/`. Ovaj dokument sam po sebi ništa ne objavljuje i ne pokreće sandbox.

Trenutačno imamo preuzet originalni track i službeni Labs skeleton. To nije gotov port. Ranije su prošli validacija originalnog tracka i validacija praznog Labs skeletona; to ne potvrđuje da Coral lab radi.

U dokumentu razlikujemo:

- **Potvrđeno u izvoru:** ponašanje koje je vidljivo u preuzetom tracku, HCL shemi, CLI-ju ili runtime kodu.
- **Prijedlog porta:** konkretan način na koji ćemo prenijeti funkcionalnost, još nije implementiran.
- **Za live provjeru:** ponašanje koje trebamo potvrditi u stvarnoj objavljenoj/testnoj sesiji.

HCL primjeri prikazuju relevantne dijelove, nisu kompletan, međusobno neovisan set konfiguracija. Nisu validirani kao dovršen Coral lab. Posebno VM image mora biti dostupan u ciljnom Labs okruženju.

## 2. Root folder i predložena organizacija

Root projekta je `/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre`.

```text
labs-2-ga-coral-ai-sre/
├── PORTING-GUIDE.md           # ovaj dokument
├── track/                    # preuzeti original; NE MIJENJATI
│   ├── track.yml
│   ├── config.yml
│   ├── assets/icon.png
│   ├── track_scripts/setup-k8s
│   ├── 01-meet-the-stack/
│   ├── 02-one-sql-connection/
│   ├── 03-agent-online/
│   ├── 04-the-incident/
│   └── 05-read-only-by-design/
└── lab/                      # zasad službeni skeleton
    ├── main.hcl              # lab, settings i redoslijed sadržaja
    ├── layouts.hcl           # raspored panela i tabova
    ├── sandboxes.hcl         # predloženo: VM, network, AWS
    ├── tabs.hcl              # predloženo: terminal, services, editor
    ├── content.hcl           # predloženo: page resursi
    ├── tasks.hcl             # predloženo: taskovi i lifecycle skripte
    ├── variables.hcl         # opcionalno: parametri i izvedene vrijednosti
    ├── instructions/         # Markdown bez starog challenge frontmattera
    ├── scripts/              # kopije i prilagodbe originalnih skripti
    ├── assets/               # npr. kopija ikone
    ├── files/                # statičke datoteke, ako ih izdvojimo
    └── notes/
```

Nazivi HCL datoteka su organizacijska konvencija. Loader čita `.hcl` datoteke u odabranom direktoriju; ne traži automatski sve poddirektorije. Moduli su zaseban mehanizam. Zato validiramo **`lab/`, a ne zajednički root**. Ako Git repo obuhvaća oba foldera, kod importa postavljamo lab directory na `/lab`.

Izvor: [HCL resolver](/Users/lovrostrihic/Workspace/instruqt/mono/hcl/resolver/resolver.go:149).

## 3. Mentalni model: što se promijenilo

Track spaja infrastrukturu iz `config.yml`, opće postavke iz `track.yml` i challenge foldere. Labs koristi povezane HCL resurse. Sadržaj i sandbox nisu ista hijerarhija:

```text
lab
└── content → chapter → page → task / quiz
                        │
                        └── layout → terminal / service / editor / cloud_credentials
                                        │
                                        └── VM / cloud account / ostali resursi
```

Referenca poput `resource.vm.k8s` povezuje resurse; nije samo string s hostnameom. Ovisnosti proizlaze iz referenci. Primjerice, VM koji koristi generirane AWS ključeve ovisi o AWS accountu.

Za ovaj port predlažemo **jedan chapter s pet pageova i po jednim taskom**, u originalnom redoslijedu. Time zadržavamo postojeći tok bez izmišljanja dodatnih vježbi. Kasnije je moguće razlomiti provjere na više taskova, ali to mijenja strukturu iskustva i treba odvojeno testirati.

| Track | Labs ekvivalent | Što stvarno treba napraviti |
| --- | --- | --- |
| `track.yml` | `resource "lab"` | Prenijeti podržane metapodatke i settings; ostale zasebno provjeriti. |
| `config.yml` VM | `resource "vm"` + `resource "network"` | Odabrati Labs image, CPU/RAM, mrežu i startup. |
| `config.yml` AWS account | `resource "aws_account"` + `user` | Prenijeti regije, servise i IAM politiku te eksplicitno povezati credentials. |
| Challenge folder | `resource "page"` + `resource "task"` | Upute i provjera postaju odvojeni resursi. |
| `assignment.md` frontmatter | HCL metadata, layout i content reference | Ne kopirati stari YAML kao konfiguraciju pagea. |
| `assignment.md` body | Markdown kroz `page.file` | Prilagoditi komponente, linkove na tabove i task embed. |
| `track_scripts/setup-k8s` | VM `startup_script` | Prilagoditi legacy bootstrap i AWS environment. |
| Challenge `setup-k8s` | Task condition `setup` | Provjeriti kada se task otključava i setup pokreće. |
| `check-k8s` | Task condition `check` | Sačuvati logiku, exit kodove i feedback; prilagoditi Bash. |
| `solve-k8s` | Task condition `solve` | Sačuvati rješenje i provjeriti skip/test flow. |
| Terminal tab | `resource "terminal"` | Referenca na VM i eksplicitni shell. |
| Service tab | `resource "service"` | Target, port, scheme i path. |
| Code tab | `resource "editor"` s workspaceom | Target VM i direktorij unutar VM-a. |
| AssignmentRight / sidebar 35% | `resource "layout"` | Alati lijevo, upute desno, približno 65/35. |
| Automatska track identifikacija | Novi lab kroz Labs/VCS workflow | Ne prenositi stari track ID, owner ili checksum kao lab identitet. |

## 4. Metapodaci, settings i redoslijed

Original ima ukupni limit 3600 sekundi, idle timeout 600 sekundi, vidljivi timer, `modern-dark` temu i vidljivi Stop. To se može izraziti ovako:

```hcl
resource "lab" "main" {
  title       = "AI SRE: Root-Cause an Incident with One SQL Query"
  description = "Investigate a Kubernetes incident with Coral SQL and Claude Code over MCP."
  icon        = "assets/icon.png"
  layout      = resource.layout.meet_the_stack

  settings {
    theme = "modern-dark"
    timelimit {
      duration   = "1h"
      show_timer = true
    }
    idle {
      enabled = true
      timeout = "10m"
    }
    controls {
      show_stop = true
    }
  }

  content {
    chapter "coral-ai-sre" {
      title = "AI SRE with Coral"
      page "meet-the-stack" {
        reference = resource.page.meet_the_stack
        layout    = resource.layout.meet_the_stack
      }
      page "one-sql-connection" {
        reference = resource.page.one_sql_connection
        layout    = resource.layout.one_sql_connection
      }
      page "agent-online" {
        reference = resource.page.agent_online
        layout    = resource.layout.agent_online
      }
      page "the-incident" {
        reference = resource.page.the_incident
        layout    = resource.layout.the_incident
      }
      page "read-only-by-design" {
        reference = resource.page.read_only_by_design
        layout    = resource.layout.read_only_by_design
      }
    }
  }
}
```

Opis u primjeru je skraćen: pri stvarnom portu prenijeti smisao originalnog opisa, a njegov HTML/styling provjeriti u Labs rendereru. Kopirati ikonu u novi `lab/assets/`, ne premještati original.

Nije potvrđeno 1:1 HCL mapiranje za `teaser`, track `level`/challenge `difficulty`, track `tags`, `developers`, `skipping_enabled`, `loadingMessages`, `enhanced_loading`, feedback recap/tab i `sidebar_enabled`. Ne izmišljati HCL atribute: pregledati Labs UI i zabilježiti razliku. Postojanje runtime skip metode ne znači da postoji isto authoring polje `skipping_enabled`.

Challenge `timelimit: 0` ne pretvarati u Labs page time limit: u pregledanoj page shemi takvog polja nema. Stari `slug` možemo smisleno ponovno koristiti kao novi content slug, ali stare `id` i `checksum` vrijednosti ostaju samo dio izvornog tracka.

Izvori: [originalni track.yml](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/track.yml:1), [lab schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/lab.yaml:17), [page schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/page.yaml:17).

## 5. Sandbox: VM, mreža i globalni setup

### Što original pokreće

- VM `k8s`: Ubuntu 24.04 amd64, 4 CPU, 16384 MB RAM.
- k3s s tri shop servisa: `frontend`, `orders`, `payments`.
- Prometheus, generator prometa i periodično skupljanje logova.
- Coral, SQL izvore/katalog, JSONL logove i seed Parquet podatke.
- Claude Code, Bedrock konfiguraciju i pomoćnu naredbu `submit`.
- Web pristup shopu, Prometheusu i Coral UI-ju.

Prvi port treba zadržati taj raspored. Prebacivanje svega u zasebne Labs containere bio bi dodatni redizajn, a ne nužna migracija.

### VM HCL uzorak

```hcl
resource "network" "main" {
  subnet = "10.50.0.0/24"
}

resource "vm" "k8s" {
  config {
    arch = "x86_64"
  }
  image {
    # Primjer naziva; dostupnost ovog VM imagea treba potvrditi u Labsu.
    name = "ubuntu:24.04"
  }
  resources {
    cpu    = 4
    memory = 16384
  }
  network {
    id = resource.network.main.meta.id
  }

  environment = {
    INSTRUQT_AWS_ACCOUNT_BEDROCK_AWS_ACCESS_KEY_ID     = resource.aws_account.bedrock.user.0.access_key_id
    INSTRUQT_AWS_ACCOUNT_BEDROCK_AWS_SECRET_ACCESS_KEY = resource.aws_account.bedrock.user.0.secret_access_key
  }

  startup_script = file("scripts/setup-k8s.sh")
}
```

Legacy GCE image `ubuntu-os-cloud/ubuntu-2404-lts-amd64` nije automatski Labs image naziv. Labs VM image također nije običan proizvoljni Docker image. Potvrditi dostupni image/preset, arhitekturu i boot u ciljnom okruženju. Coral binary iz originalnog setupa očekuje noviji glibc; zato ne spuštati Ubuntu 24.04 na 22.04 samo radi dostupnosti primjera.

Mrežna referenca također ovisi o verziji: aktualna `mono` shema označava `network.id` kao deprecated i predlaže `target = resource.network.main`, dok pregledani `lab-sdk v1.98.3` attachment još deklarira `id`. Primjer gore zadržava oblik tog runtimea. Pri portanju provjeriti što prihvaćaju konkretni CLI, import i runtime; ne zamijeniti oblik samo prema novijoj shemi bez te provjere. Izvori: [network schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/shared-types.yaml:10), [runtime attachment](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/hcl/resources/network/attachment.go:18).

`allow_external_ingress: [http, https, high-ports]` nije polje koje samo kopiramo u Labs VM. Web alate izlažemo kroz service resurse i provjeravamo stvarnu mrežnu dostupnost. Dodatne VM port/port_range postavke koristiti samo kad postoji potreba; ne otvarati sve portove radi oponašanja starog YAML-a.

### Obvezne prilagodbe globalnog setupa

1. Kopirati sadržaj originalnog setupa u `lab/scripts/setup-k8s.sh`; original ostaje netaknut.
2. U kopiji ukloniti/prilagoditi čekanje na `/opt/instruqt/bootstrap/host-bootstrap-completed`. To je legacy marker; odgovarajući Labs marker nije pronađen u pregledanom runtimeu. Ostavljanje petlje može trajno zaustaviti setup. Ne stvarati lažni marker da bi se problem sakrio.
3. Sačuvati `#!/bin/bash` i Bash logiku. VM startup provider izvršava pripremljenu skriptu kao datoteku i poštuje shebang. To se razlikuje od task skripti opisanih niže.
4. Zadržati Ubuntu/Coral kompatibilnost, seed podatke, timere, proxyje i CLI helper funkcionalnost.
5. AWS varijable povezati eksplicitno, kao iznad. Ista imena omogućuju da originalna logika stvaranja `~/.aws/credentials` ostane prepoznatljiva.
6. Provjeriti spremnost k3s workloadova i Coral servisa, ne samo uspješan izlaz iz instalacije. Startup u pregledanom provideru ide nakon agent/network readinessa, a prije konfiguriranih healthcheckova.

**Zašto startup, a ne globalni `exec` target VM?** U pregledanom `lab-sdk` runtimeu `exec` poznaje VM, ali `mono` validator za `exec.target` prihvaća samo container; isti problem postoji i u verziji validatora koju koristi ovaj CLI. To je potvrđena neusklađenost izvora, ne potvrđena greška produkcijske sesije. VM `startup_script` je ovdje smisleniji početni put. Task `config.target = resource.vm.k8s` zasebno je podržan.

Izvori: [config.yml](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/config.yml:1), [legacy setup](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/track_scripts/setup-k8s:1), [VM startup redoslijed](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/hcl/resources/vm/provider.go:244), [startup izvršavanje](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/hcl/resources/vm/provider.go:337), [exec validator](/Users/lovrostrihic/Workspace/instruqt/mono/hcl/validate/entities/exec/validator.go:227).

## 6. AWS account i Bedrock credentials

Original koristi account `bedrock`, servis `bedrock`, regije `us-east-1`, `us-east-2`, `us-west-2` i managed policy `AmazonBedrockLimitedAccess`.

```hcl
resource "aws_account" "bedrock" {
  services = ["bedrock"]
  regions  = ["us-east-1", "us-east-2", "us-west-2"]

  user "student" {
    managed_policies = [
      "arn:aws:iam::aws:policy/AmazonBedrockLimitedAccess"
    ]
  }
}

# Dodatna testna pokrivenost; ovaj tab nije dio originalnih pet layouta.
resource "cloud_credentials" "bedrock" {
  aws_account {
    target = resource.aws_account.bedrock
    users  = ["student"]
  }
}
```

- IAM managed policy ide na `user` blok. Account `services`/`regions` i eventualni `scp_policy` predstavljaju drugi sloj ograničenja; jedno nije zamjena za drugo.
- `cloud_credentials.users` sadrži authored slug `student`, ne generirani AWS username.
- Credentials tab nije zamjena za environment VM-a. Skriptama je i dalje potrebno eksplicitno dostaviti vrijednosti.
- `user.0` je referenca na prvog deklariranog korisnika. Trenutačni `mono` testovi pokrivaju i named oblik `user.student`; ne zaključivati iz starijih bilježaka da je named oblik nužno pokvaren. U ciljnom parser/runtime toku provjeriti oba ako je to dio GA testa.
- Ako bude potreban custom `iam_policy`, `file(...)`/`jsonencode(...)` imaju testove u aktualnom `mono`; ranije prijavljene probleme treba ponovno reproducirati prije prijave kao aktualnog buga.
- Ne stavljati stvarne access/secret ključeve u HCL, Markdown, commit ili screenshot. Ovaj track treba provisionirani account, a ne privatne korisnikove AWS ključeve.

Originalni setup konfigurira Claude za `AWS_REGION=us-east-1`, Bedrock način rada, Sonnet model `us.anthropic.claude-sonnet-4-6` i Haiku `us.anthropic.claude-haiku-4-5-20251001-v1:0`. To su vrijednosti pronađene u tracku, ne jamstvo trenutačne dostupnosti modela. Sačuvati ih kao početnu točku i potvrditi stvarni poziv kroz Claude Code → Coral MCP → Bedrock. Kreiran IAM user ili uspješni `claude mcp list` nisu dovoljan dokaz.

Izvori: [AWS schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/aws_account.yaml:17), [Claude/AWS setup](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/track_scripts/setup-k8s:593), [dual indexing fixture](/Users/lovrostrihic/Workspace/instruqt/mono/hcl/testdata/dual_indexing/main.hcl:49), [AWS account dokumentacija](https://docs.labs.instruqt.com/reference/sandbox/cloud/aws/account/), [cloud credentials dokumentacija](https://docs.labs.instruqt.com/reference/sandbox/ui/cloud-credentials/).

## 7. Svih pet challengea: što se prenosi

Za svaki red kopiramo Markdown body u zasebnu datoteku u `lab/instructions/`, definiramo `page`, povežemo jedan `task` i dodamo page u `lab.content`.

| Originalni folder | Novi page/task | Skripte koje treba prenijeti | Svrha i provjera |
| --- | --- | --- | --- |
| `01-meet-the-stack` | `meet_the_stack` | `check-k8s`, `solve-k8s` | Upoznati zdrav stack, shop, Prometheus i podatke. Check uglavnom provjerava već spremnu infrastrukturu. |
| `02-one-sql-connection` | `one_sql_connection` | `check-k8s`, `solve-k8s` | Coral SQL izvori/katalog i povezivanje različitih izvora kroz jedan SQL pristup. |
| `03-agent-online` | `agent_online` | `check-k8s`, `solve-k8s` | Registracija Coral MCP-a u Claude Code i agent warmup. Check traži registraciju i datoteku s dokazom; ručno dodatno potvrditi stvaran round-trip. |
| `04-the-incident` | `the_incident` | `setup-k8s`, `check-k8s`, `solve-k8s` | Setup namjerno kvari payments; learner istražuje i predaje uzrok. Sačuvati live-truth grading i dokaz istraživanja. |
| `05-read-only-by-design` | `read_only_by_design` | `setup-k8s`, `check-k8s`, `solve-k8s` | Setup vraća zdravo stanje. Dokazati odbijanje mutacije i dodati stvarno queryable `shopapi` source. |

Detalj 2. challengea: check traži sva tri sourcea (`k8s`, `prometheus`, `shopdata`), izvršava stvarni JOIN `k8s.pods` i `shopdata.logs` te traži spremljeni learner rezultat u `/root/answers/first-join.txt` s podovima shop servisa. Sačuvati sve tri razine provjere. Izvor: [SQL check](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/02-one-sql-connection/check-k8s:1).

Detalj 3. challengea: originalni solve može registrirati MCP i napisati warmup marker izravnim `coral sql` pozivom, bez stvarnog Claude/Bedrock razgovora. Zato zelen solve/check nije dokaz da agent round-trip radi. To je ograničenje postojećeg grader dokaza, ne automatski Labs bug. Izvor: [agent solve](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/03-agent-online/solve-k8s:1).

Važan detalj 4. challengea: setup postavlja `SVC_VERSION=v2` na payments i uklanja `PAYMENT_GATEWAY_URL`. Check traži odgovor u `/root/answers/q1.txt`, uspoređuje ga sa stvarno pokvarenim deploymentom i traži `/root/answers/alerts.txt`. Ne zamijeniti ga trivijalnim checkom „odgovor je payments“: original ima namjernu provjeru živog stanja.

Važan detalj 5. challengea: setup vraća payments na zdravu konfiguraciju i priprema specs. Check traži `/root/answers/mutation-attempt.txt`, stvarni `/root/specs/shopapi.yaml`, instaliran source i uspješan SQL query. Postojanje YAML datoteke samo po sebi nije dovoljno.

### Page i aktivnost moraju biti povezani s obje strane

```hcl
resource "page" "meet_the_stack" {
  title = "Meet the Stack You're On Call For"
  file  = "instructions/meet-the-stack.md"

  activities = {
    check_stack = resource.task.meet_the_stack
  }
}
```

Na odgovarajuće mjesto u Markdownu dodati:

```html
<instruqt-task id="check_stack"></instruqt-task>
```

ID u Markdownu mora odgovarati ključu u `activities`. Runtime provjerava nedostajuće/neiskorištene/duplicirane activity ID-jeve. Ako imamo više aktivnosti, redoslijed njihovog pojavljivanja u Markdownu određuje slijed, ne redoslijed ključeva u HCL mapi.

Izvori: [page processing](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/hcl/resources/page/resource.go:93), [slaganje aktivnosti](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/hcl/resources/lab/provider.go:115), [incident check](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/04-the-incident/check-k8s:1), [read-only check](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/05-read-only-by-design/check-k8s:1).

## 8. Lifecycle skripte: najvažnije razlike

### Task HCL uzorak

```hcl
resource "task" "the_incident" {
  description     = "Find the root cause of the checkout incident."
  success_message = "You identified the failing service and recorded your investigation."

  config {
    target            = resource.vm.k8s
    user              = "root"
    group             = "root"
    working_directory = "/root"
    timeout           = "3m"
  }

  condition "root_cause" {
    description = "Submit the live root cause and investigation evidence."
    setup {
      script = "scripts/the-incident/setup.sh"
      config {
        timeout = "5m"
      }
    }
    check {
      script          = "scripts/the-incident/check.sh"
      failure_message = "Check your submitted root cause and saved alerts query."
    }
    solve {
      script = "scripts/the-incident/solve.sh"
    }
  }
}
```

Timeouti iz primjera su prijedlog za početak testiranja, ne izmjereni zahtjev. Originalni incident setup već čeka rollout do 120 sekundi; default 30 sekundi task skripte može biti prekratak.

### Što znači `script`

`script = "scripts/.../check.sh"` je **putanja izvornog fajla u lab konfiguraciji**, relativno HCL datoteci koja ga deklarira. Target određuje gdje se sadržaj izvršava. Ne znači da je taj isti fajl automatski instaliran na `/root/scripts/...` unutar VM-a.

Nasuprot tome, `startup_script = file("scripts/setup-k8s.sh")` koristi funkciju `file()` za čitanje sadržaja. `page.file` opet očekuje putanju Markdowna. Te tri stvari ne treba međusobno zamjenjivati.

### Bash nije automatski zajamčen za task skripte

U pregledanom VM task runtimeu sadržaj se šalje kao **`sh -c <sadržaj>`**. `#!/bin/bash` na prvoj liniji tada je samo komentar; `chmod +x` lokalnog fajla i `terminal.shell = "/bin/bash"` ne mijenjaju task interpreter.

Originalne task skripte koje koriste Bash treba u kopiji eksplicitno izvršiti Bashom ili prepisati u POSIX shell. Uzorak za zadržavanje postojećeg sadržaja:

```sh
exec /bin/bash <<'CORAL_TASK_BASH'
# Ovdje ide stvarni sadržaj kopirane originalne skripte.
# Zadržati njezine exit kodove i izvorne shell opcije.
CORAL_TASK_BASH
```

Odabrati delimiter koji se ne pojavljuje u originalnom sadržaju. `exec` prenosi rezultat Bash procesa; citirani heredoc sprečava da vanjski `sh` prerano interpolira Bash sadržaj. Za skripte koje trebaju stdin napraviti zasebnu prilagodbu umjesto slijepog omatanja. VM startup skripta ima drugi mehanizam i ne treba ovaj wrapper samo zato što ga trebaju taskovi.

### Feedback, exit kodovi i konfiguracija

- Task → condition → pojedinačna skripta: uži `config` nadjačava naslijeđene vrijednosti. Pregledani defaulti su root/root, direktorij `/`, timeout 30 s.
- Sve potrebne condition/check provjere trebaju proći. Lifecycle blokovi se u uobičajenom toku izvršavaju sekvencijalno.
- Exit `0` je standardni uspjeh. Neuspjeli check i greška izvršavanja nisu ista stvar; custom `success_exit_codes`/`failure_exit_codes` mijenjaju klasifikaciju. Sačuvati izvorne kodove i provjeriti failed/error prikaz.
- Legacy `fail-message` helper nije pronađen u pregledanom Labs runtimeu. Original često koristi `fail-message ... || true`, pa helper može nedostajati bez prekida, ali learner izgubi detaljnu poruku.
- Za početni port staviti jasan `failure_message` u HCL. Za očuvanje svih specifičnih originalnih poruka razlomiti logičke provjere u uvjete/checkove ili potvrditi podržani način dinamičkog feedbacka. Obični `echo` u stdout nije dokaz da UI prikazuje istu learner poruku.

### Kada se setup zaista pokreće

U pregledanom runtimeu setup se pokreće **pri otključavanju taska**, a ne nužno tek kad learner klikne sljedeći page. Dovršavanje/skipping prethodne aktivnosti može otključati sljedeću. Zato posebno testirati:

1. Kada se nakon 3. taska stvarno ubacuje incident?
2. Može li 5. setup izliječiti stack dok learner još čita rezultat 4. taska?
3. Što se događa na skip, povratak na raniji page i ponovno otvaranje sesije?

Nemojmo pretpostaviti da deklarirani `prerequisites` sami rješavaju sve prijelaze; za planirani redoslijed potvrditi stvarno runtime ponašanje.

### Solve, cleanup i reset

Pregledani skip put poziva solve i označava task kao skipped. To treba potvrditi u UI-ju i automatiziranom testu, zajedno s prikazom eventualne solve greške.

`cleanup` postoji u modelu i postoji eksplicitni `Task.Clean()`, ali pregledani ValidateTask/SkipTask tokovi ne pozivaju ga automatski. **Ne oslanjati se na cleanup pri svakom Check/Next/Skip događaju**, bez potvrde konkretnog caller toka. Također nije pronađen odgovarajući reset lifecycle na koji bismo sigurno mapirali legacy reset. Ovaj original nema challenge cleanup/reset skripte, pa ih ne treba izmišljati.

Izvori: [task schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/task.yaml:17), [VM task interpreter](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/state/script.go:100), [task state](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/state/task.go:129), [condition setup](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/state/condition.go:128), [cleanup](/Users/lovrostrihic/Workspace/instruqt/lab-sdk/pkg/state/task.go:288), [ValidateTask/SkipTask](/Users/lovrostrihic/Workspace/instruqt/lab-agent/pkg/server/lab/service.go:444).

## 9. Tabovi i layouti — očuvati razlike po pageu

| Page | Tabovi originalnog tracka, redom |
| --- | --- |
| Meet the Stack | Terminal; The Reef Shop `30080/`; Prometheus `30990/alerts` |
| One SQL Connection | Terminal; Coral UI `11457/`; Data Files editor `/root/data` |
| Agent Online | Terminal; Coral UI `11457/` |
| The Incident | Terminal; The Reef Shop `30080/`; Coral UI `11457/` |
| Read-Only by Design | Terminal; Spec Editor `/root/specs` |

Resurse definiramo jednom, a layout po pageu bira odgovarajući podskup i redoslijed. Nemojmo svih pet pageova zamijeniti jednim layoutom sa svim tabovima: to bi promijenilo iskustvo i stare tab linkove.

```hcl
resource "terminal" "shell" {
  target            = resource.vm.k8s
  shell             = "/bin/bash"
  user              = "root"
  working_directory = "/root"
}

resource "service" "shop" {
  target = resource.vm.k8s
  port   = 30080
  scheme = "http"
  path   = "/"
}

resource "service" "prometheus" {
  target = resource.vm.k8s
  port   = 30990
  scheme = "http"
  path   = "/alerts"
}

resource "service" "coral_ui" {
  target = resource.vm.k8s
  port   = 11457
  scheme = "http"
  path   = "/"
}

resource "editor" "data_files" {
  workspace "data" {
    directory = "/root/data"
    target    = resource.vm.k8s
  }
}

resource "editor" "specs" {
  workspace "specs" {
    directory = "/root/specs"
    target    = resource.vm.k8s
  }
}

resource "layout" "meet_the_stack" {
  column {
    width = "65"
    tab "terminal" {
      title  = "Terminal"
      target = resource.terminal.shell
    }
    tab "shop" {
      title  = "The Reef Shop"
      target = resource.service.shop
    }
    tab "prometheus" {
      title  = "Prometheus"
      target = resource.service.prometheus
    }
  }
  column {
    width = "35"
    instructions {}
  }
}
```

Provjeriti stvarno renderirani omjer i responsivnost. Aktualni layout koristi labeled `tab` blokove i `target` reference; stari primjeri s `type = "terminal"` i `terminal = ...meta.id` nisu predložak za ovaj port.

Service tab treba provjeriti kroz browser proxy, ne samo `curl localhost` u VM-u. Original već ima Coral proxy s `127.0.0.1:1457` na dostupni `11457`; sačuvati ga dok nije dokazano da nije potreban. Testirati shop kupnju, Prometheus Alerts i Coral query UI. Editor mora prikazivati i spremati datoteke stvarnog VM-a, ne lab repozitorija.

Izvori: [terminal schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/terminal.yaml:17), [service schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/service.yaml:17), [editor schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/editor.yaml:17), [layout schema](/Users/lovrostrihic/Workspace/instruqt/mono/schemas/layout.yaml:17), [layout reference](https://docs.labs.instruqt.com/reference/content/layout/).

## 10. Markdown, notes, datoteke i assets

### Upute i komponente

1. Odvojiti challenge YAML frontmatter od Markdown bodyja. Naslov ide u page, tabovi u resurse/layout, redoslijed u lab content.
2. Originalne `notes` s uvodnim HTML-om imaju edukativni sadržaj. Prenijeti ga u uvod odgovarajućeg pagea ili potvrđeni Labs notes mehanizam; ne izgubiti ga samo zato što uklanjamo frontmatter.
3. Provjeriti HTML, inline stilove, calloute, slike i linkove kroz stvarni Labs renderer.
4. Stari `[button label="Terminal" variant="outline"](tab-0)` vezan je za tab indeks. Podršku/novi oblik linka potvrditi u Labsu; ne pretpostaviti da kopiranje teksta čuva ponašanje.
5. `bash,run` blokovi dokumentirani su i za Labs. Treba terminal u layoutu; kod više terminala izbor odredišta može biti drukčiji. Testirati konkretan Run klik i učinak u VM-u.
6. Zamijeniti tekst „Click Check / next challenge“ uputom koja odgovara embedded Labs tasku i page navigaciji.
7. Na kraju predvidjeti Labs completion komponentu i testirati završetak sesije:

```html
<instruqt-completion></instruqt-completion>
```

Prolazak posljednjeg taska, dosegnut kraj pagea i završena sesija nisu pojmovi koje treba automatski izjednačiti. Provjeriti i reporting.

### Tri vrste datoteka

| Vrsta | Primjer | Portanje |
| --- | --- | --- |
| Authoring datoteke | HCL, Markdown, lifecycle skripte | Čita ih lab loader; nisu zato automatski na learner VM-u. |
| Statički assets/podaci | `assets/icon.png`, eventualno izdvojeni seed ili spec | Kopirati u `lab/` i eksplicitno referencirati; za upotrebu u VM-u definirati način dostave. |
| Runtime datoteke | `/root/data/logs.jsonl`, `/root/answers/*`, `/root/specs/*` | Stvara ih setup/learner unutar VM-a; editor i checkovi moraju gledati te putanje. |

Original seed Parquet nastaje iz base64 sadržaja setupa i ima vlastitu pomoćnu logiku za oporavak. Za prvi port to sačuvati. Izdvajanje u `lab/files/` je moguća dodatna files testna pokrivenost, ali zahtijeva provjeren prijenos u VM i ne smije promijeniti podatke/ponašanje. Samo postojanje `files/` foldera nije prijenos datoteka.

Izvori: [originalni assignment i frontmatter](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/01-meet-the-stack/assignment.md:1), [seed u setupu](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/track_scripts/setup-k8s:455), [page reference](https://docs.labs.instruqt.com/reference/content/page/), [completion dokumentacija](https://docs.labs.instruqt.com/ui-overview/adding-content/completion/).

## 11. Dinamičke vrijednosti i tajne

Labs HCL nije Terraform konfiguracija i ne treba prepisivati Terraform sintaksu napamet:

```hcl
variable "aws_region" {
  default = "us-east-1"
}

local "region_label" {
  value = "Bedrock region: ${variable.aws_region}"
}

output "region_label" {
  value = local.region_label
}
```

Koristimo `variable.aws_region`, ne `var.aws_region`; deklaracija je `local "ime" { value = ... }`, ne Terraform `locals { ... }`.

Page može proslijediti vrijednosti Markdown predlošku:

```hcl
# Unutar odgovarajućeg resource "page" bloka:
variables = {
  aws_region = variable.aws_region
}
```

```markdown
Claude Code u ovom labu koristi AWS regiju {{aws_region}}.
```

HCL `${...}` i Markdown `{{...}}` su različiti slojevi interpolacije. Inline shell `${...}` unutar HCL heredoca treba escapeati kao `$${...}` ako ga treba dobiti shell. Vanjski `.sh` učitan s `file()` izbjegava HCL interpretaciju samog shell sadržaja.

Dokumentirani ugrađeni nazivi uključuju `variable.instruqt_session_id`, `variable.instruqt_team_id`, `variable.instruqt_team_slug`, `variable.instruqt_lab_id`, `variable.instruqt_lab_slug`, `variable.instruqt_user_id` i `variable.instruqt_sandbox_domain`. Prefix `instruqt_` je rezerviran za platformu; ne koristiti ga za vlastite varijable.

Team-managed secrets koriste `resource "secret"` i runtime vrijednost `.value`; konkretan secret konfigurirati samo ako ga scenarij treba. Ovdje provisionirani AWS account već daje potrebne credentials. Nikad ne prikazivati secret kroz običan page variable/output samo radi dokazivanja dinamičkih vrijednosti.

Original većinom ima hardcoded regiju, modele, lokalne URL-ove i putanje. Njihovo izdvajanje u variables/locals je **dodatna testna pokrivenost**, a ne obvezan uvjet očuvanja originalnog ponašanja. Ako to radimo, povezati istu vrijednost i sa skriptom i s uputama: promijenjen tekst bez promijenjenog runtimea nije uspješan port.

Izvori: [variable reference](https://docs.labs.instruqt.com/reference/types/variable/), [local reference](https://docs.labs.instruqt.com/reference/types/local/).

## 12. CLI, import i objava

Lokalno izgrađeni CLI: `/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt`, verzija `2422-e3774cd`.

Potvrđene Labs naredbe ovog builda su `init`, `format`/`fmt`, `validate`, `test` i `logs`. **Nema `lab push`, `lab create` ni `lab deploy` naredbe** u pregledanom command registru. Ne koristiti stare WIP primjere kao dokaz da postoje.

Za budući port, nakon stvarnih promjena u `lab/`:

```bash
# Format mijenja HCL datoteke samo unutar novog lab foldera.
/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt lab format \
  /Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/lab

# Lokalna statička validacija; ne provisionira VM i ne izvršava taskove.
/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt lab validate \
  /Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/lab
```

Skeleton je već inicijaliziran; ne ponavljati `lab init` preko postojećeg rada. Nije potrebno niti dopušteno dirati originalni track da bismo objavili novi lab.

Objava ide kroz odgovarajući **Labs UI/VCS import i publish workflow**, ne legacy track push. Ako odaberemo vanjski Git:

1. Odabrati odredišni team, novi lab identitet i repo/branch.
2. U integraciji odabrati `/lab` kada repo root sadrži ovaj zajednički projekt.
3. Provjeriti import/parse rezultat i draft/committed verziju koju otvaramo.
4. Play/testati točno određeni ref ili workspace; zatim zasebno provjeriti publish i learner pristup.
5. Jasno odrediti izvor promjena između lokalnog Gita i UI workspacea, da ne testiramo staru ili drugu verziju.

Kreiranje/push repozitorija, stvaranje remote laba i objavljivanje nisu napravljeni ovim dokumentom; odredište treba odabrati prije tih radnji.

Kad remote lab postoji, ovo su predlošci naredbi — zamijeniti vrijednosti u navodnicima:

```bash
# Pokreće remote sandbox i troši resurse; nije lokalni dry run.
/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt lab test \
  'TEAM/LAB' --ref 'BRANCH_OR_TAG' --scope sandbox

# Pokreće remote test sadržaja.
/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt lab test \
  'TEAM/LAB' --ref 'BRANCH_OR_TAG' --scope content

# Alternativa za draft: --workspace umjesto odabira committed refa.
/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt lab test \
  'TEAM/LAB' --workspace 'WORKSPACE_ID' --scope content

/Users/lovrostrihic/Workspace/instruqt/go-cli/bin/instruqt lab logs \
  --session 'SESSION_ID' --since '-30m'
```

CLI prekid praćenja testa nije dokaz da je server-side test workflow zaustavljen; provjeriti status i pravilno završiti sesiju.

Izvori: [CLI registry i flagovi](/Users/lovrostrihic/Workspace/instruqt/go-cli/pkg/cli/cmd/lab.go:38), [local validate](/Users/lovrostrihic/Workspace/instruqt/go-cli/pkg/cli/lab/validate.go:13), [remote test](/Users/lovrostrihic/Workspace/instruqt/go-cli/pkg/cli/lab/test.go:29), [external VCS](https://docs.labs.instruqt.com/version-control/integrating-external-vcs/), [editing/publishing](https://docs.labs.instruqt.com/ui-overview/editing-and-publishing/).

## 13. Plan portanja i kriteriji prolaza

Raditi ovim redom; svaka etapa daje zaseban dokaz:

- [ ] Sačuvati originalni `track/` i njegov hash baseline. Sve prilagodbe raditi u `lab/`.
- [ ] Kopirati ikonu, upute i skripte u novi lab te napraviti HCL poveznice.
- [ ] Definirati AWS account/user, VM/network i credentials reference.
- [ ] Potvrditi dostupan Ubuntu 24.04 x86_64 VM image.
- [ ] Prilagoditi globalni startup: legacy marker, environment, readiness.
- [ ] Prenijeti pet taskova, Bash izvršavanje, feedback i realistične timeoute.
- [ ] Definirati terminal/services/editore i svih pet page layouta.
- [ ] Prilagoditi Markdown komponente, Run blokove, tab linkove i completion.
- [ ] Pokrenuti format i statičku validaciju isključivo novog laba.
- [ ] Nakon odabira remote odredišta importati i testirati sandbox boot.
- [ ] Ručno proći svih pet pageova u novoj learner sesiji.
- [ ] Testirati content runner, skip/solve i lifecycle prijelaze; zabilježiti očekivane razlike.
- [ ] Objaviti namijenjenu verziju i ponovno provjeriti Play te Reporting → Sessions.
- [ ] Usporediti sadržaj/ponašanje s originalom i zasebno popisati dodanu GA pokrivenost.

### Što mora raditi uživo

- VM i AWS spremni; startup završi bez čekanja na legacy marker.
- Svi shop workloadovi zdravi prije incidenta; shop kupnja prolazi.
- Prometheus Alerts i Coral UI rade kroz learner tabove.
- SQL izvori vraćaju stvarne podatke; learner izvrši cross-source JOIN.
- Claude Code koristi Bedrock i stvarno pristupa Coral MCP alatima.
- Incident se aktivira u ispravnom trenutku; odgovor se gradi iz živih podataka.
- Zadnji dio oporavi stack, Coral odbije mutaciju i novi `shopapi` source vraća podatke.
- Editori spremaju u pravi VM; taskovi provjeravaju to isto stanje.
- Namjerno pogrešno rješenje daje razumljiv failure; ispravno rješenje prolazi.
- Skip/solve ne zaobilazi potrebni setup niti prerano mijenja stanje koje learner još treba vidjeti.
- Završetak je vidljiv u learner UI-ju i odgovarajućoj sesiji u reportingu.

### Posebna zamka automatiziranog content testa

Pregledani test worker očekuje da check **ne prođe na netaknutom tasku**, zatim pokreće solve i očekuje prolaz. Prvi Coral challenge provjerava infrastrukturu koja je već spremna nakon setupa i zato može legitimno odmah proći.

Zbog toga content test može prijaviti `the check passed on an untouched task` iako ručni learner flow ima smisla. Ne kvariti originalni check niti dodavati umjetni marker samo da runner bude zelen. Najprije reproducirati i zabilježiti razliku između runner ugovora i ovog scenarija. `--scope sandbox` dokazuje samo boot; nije zamjena za sadržajni test ili ručni prolaz.

Izvori: [test worker očekivanje](/Users/lovrostrihic/Workspace/instruqt/mono/services/labs/test-worker/internal/workflows/lab_test_run.go:375), [prvi check](/Users/lovrostrihic/Workspace/instruqt/labs-2-ga-coral-ai-sre/track/01-meet-the-stack/check-k8s:1), [testing deployment](https://docs.labs.instruqt.com/getting-started/code/testing-deployment/).

## 14. Otvoreni nalazi i GA bilješke

Ovo nisu automatski svi potvrđeni bugovi proizvoda:

| Nalaz | Dokaz/status | Što napraviti |
| --- | --- | --- |
| Legacy bootstrap marker | Postoji u originalnom setupu; Labs ekvivalent nije pronađen. | Prilagoditi kopiju skripte; potvrditi startup. |
| Task Bash shebang nije dovoljan | VM task runtime koristi `sh -c`. | Eksplicitni Bash i regression prolaz svih skripti. |
| `fail-message` prenosivost | Helper nije pronađen u pregledanom Labs kodu. | Sačuvati feedback kroz task model i provjeriti UI. |
| `exec` VM target | Runtime i validator nisu usklađeni u pregledanim verzijama. | Za port koristiti VM startup; eventualnu prijavu reproducirati s verzijama. |
| Setup na unlock | Vidljivo u lifecycle kodu. | Testirati trenutak incidenta i oporavka. |
| Cleanup/reset pretpostavke | Nije potvrđen automatski cleanup u pregledanim check/skip tokovima. | Ne graditi ovisnosti na pretpostavljenom ponašanju. |
| Prvi task odmah prolazi | Originalni infrastrukturni check nasuprot test-worker ugovoru. | Odvojiti runner nalaz od stvarnog learner problema. |
| Named AWS user / policy iz datoteke | Aktualni `mono` ima odgovarajuće testove. | Retestirati u stvarnom CLI/import/runtime toku; ne ponavljati stare nalaze kao aktualne. |
| Legacy Markdown i metadata | Nije dokazano potpuno 1:1 mapiranje. | Vizualni i interakcijski pregled svakog pagea. |

Prema pregledanom test planu, ovo je **Group 2**, s članovima Jim James Campbell, Lovro Strihic, JP Joao Pedro Portela, Harpreet Singh i Daniil Malykh. Route je CLI + HCL. Assignment i sastav grupe provjeriti ponovno ako se Notion promijeni.

Fokus grupe: **B Overview, D Instructions, E Cloud-provider sandbox, F Tabs, H Dynamic values, J Files**, uz zajednički Publish/Play i Reporting Sessions smoke. Cloud credentials tab, dodatne dinamičke vrijednosti i izdvojene datoteke označiti kao dodanu pokrivenost ako nisu dio izvornog track iskustva.

Nalaze zapisivati u grupni **Notes/findings** tijekom rada, s oznakom **Blocker / Rough / Papercut**. Ne unositi samo „ne radi“; minimalni zapis:

```text
Naslov:
Autor / grupa / route: Group 2 — CLI + HCL
Ozbiljnost: Blocker | Rough | Papercut
CLI verzija / lab ref ili workspace:
Koraci za reprodukciju:
Očekivano:
Stvarno:
Lab URL / session ID / error ID:
Dokaz: relevantni logovi ili screenshot, bez credentials
Utjecaj / workaround:
Status: reproducirano uživo | samo statički nalaz | treba retest
```

Upute za samostalnu gradnju i usporedbu tek nakon objave treba uskladiti s pre-session dogovorom o jednom ekspertu po grupi. Ovaj dokument ne pretpostavlja da je konkretna osoba već izabrana za eksperta. Ništa iz dokumenta nije automatski poslano u Notion niti prijavljeno kao ticket.

## 15. Izvori i pouzdanost verzija

Primarni sadržaj za port je [originalni track u UI-ju](https://play.instruqt.com/manage/jparton-challenge/tracks/coral-ai-sre) i njegova lokalna kopija. Kontekst testiranja: [GA test plan](https://app.notion.com/p/instruqt/Labs-2-0-GA-Test-Plan-3d0fa4cf12ea817199b7d701486f78b9) i [Group 2](https://app.notion.com/p/instruqt/3d5fa4cf12ea8185a69bf9f62263bfef).

Za authoring koristimo [Labs resource reference](https://docs.labs.instruqt.com/reference/types/resource/), [lab](https://docs.labs.instruqt.com/reference/content/lab/), [page](https://docs.labs.instruqt.com/reference/content/page/), [task](https://docs.labs.instruqt.com/reference/content/task/), [VM](https://docs.labs.instruqt.com/reference/sandbox/compute/vm/) i lokalne sheme povezane uz pojedine sekcije.

Bitna razlika verzija: izgrađeni CLI na commitu `e3774cd9f` ovisi o `mono` modulu `v0.20.1-0.20260827080640-342a594b1ec5`, a lokalni aktualni `mono` je `3e87e7e18`. „Najnoviji CLI build“ zato ne znači automatski „validator iz najnovijeg mono maina“. Pregledani `lab-sdk` je `v1.98.3` / `dec5f09`, što odgovara dependencyju pregledanog lab-agenta; nije provjerena verzija svake deployane usluge.

Stariji standalone `lab-hcl`, povijesni `lab-examples` i WIP vodiči nisu jači dokaz od relevantne sheme i stvarnog ponašanja odabrane verzije. Kada se razlikuju dokumentacija, lokalni validator, import i runtime, zabilježiti sve verzije i točnu granicu na kojoj nastaje problem.

**Zaključak:** port nije promjena YAML ekstenzije u HCL. Prenosimo isti scenarij u odvojene sandbox, content, task i UI resurse, a najosjetljivije točke su interpreter skripti, startup, credentials i lifecycle prijelazi. Gotovo je tek kada isti scenarij prođe u stvarnoj Labs sesiji, ne kada prođe samo `lab validate`.
