#!/usr/bin/env bash
#
# Sets descriptions and topics on repos that are missing them.
#
# 18 of your 28 repos have no description and 24 have no topics. Blank descriptions
# read as abandoned on your repo list, in search results, and on pins.
#
# The two forks (kana-dojo, llmware) are intentionally excluded.
#
# REVIEW THE DESCRIPTIONS BELOW BEFORE RUNNING. They were inferred from repo names,
# languages, and READMEs - not written by you. Edit anything that misrepresents the work.
#
#   export GH_TOKEN=ghp_xxxx          # classic PAT, 'public_repo' scope
#   bash scripts/set-repo-metadata.sh            # fill blanks only (safe default)
#   DRY_RUN=1 bash scripts/set-repo-metadata.sh  # preview only
#   FORCE=1   bash scripts/set-repo-metadata.sh  # also OVERWRITE existing values
#
# By default this only fills in fields that are currently EMPTY - your own
# descriptions are never overwritten. Pass FORCE=1 to replace them too.
#
set -uo pipefail

USER="VrajVaghela"
API="https://api.github.com"
DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"

# Payload scratch file (see the --data-binary comment below for why).
TMP_PAYLOAD=".repo-metadata-payload.json"
trap 'rm -f "$TMP_PAYLOAD"' EXIT

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "ERROR: GH_TOKEN is not set."
  echo "  Create a classic PAT with 'public_repo' scope at https://github.com/settings/tokens"
  echo "  Then: export GH_TOKEN=ghp_xxxx"
  exit 1
fi

# repo | description | comma-separated topics
ROWS=$(cat <<'ENTRIES'
CrimeOS|Intelligence-led police investigation platform. Agentic AI for multilingual complaint intake, SOP-grounded investigation, and legal drafting. Built for ERH26.|agentic-ai,investigation-platform,nextjs,typescript,multimodal,rag,hackathon
firewall|Packet-filtering firewall written in Rust — rule evaluation and packet inspection from scratch.|rust,firewall,networking,systems-programming,packet-filtering,security
autoclassroom|Homework automation agent that works assignments end-to-end.|python,llm-agents,automation,education
odoo-hackathon|TransitOps — smart transport operations platform built for the Odoo hackathon.|typescript,nextjs,transport,logistics,hackathon
Command-Bot|Command-driven bot with a web interface. Deployed on Vercel.|typescript,bot,nextjs,vercel
jobpilot|AI job-search agent — matches roles, tailors resumes, and speeds up applications.|agentic-workflow,typescript,job-search,llm,automation
vocaba|Vocaba — language-learning mobile app built with React Native and Clerk auth.|reactnative,clerk,language-learning,mobile,expo
gitassist|AI assistant for Git workflows — turns intent into the right command.|typescript,git,developer-tools,llm,cli
nodebase|Node-based visual workspace for composing and connecting operations.|typescript,nextjs,node-editor,visual-programming
chatbot|Conversational AI agent groundwork — prompt handling and dialogue state.|python,chatbot,llm,conversational-ai
crag|Corrective RAG — retrieval-augmented generation with a relevance-grading feedback loop.|python,rag,corrective-rag,langchain,langgraph,llm
selfrag|Self-RAG — retrieval-augmented generation with self-critique and reflection tokens.|python,rag,self-rag,langchain,langgraph,llm
lagnchain-langgraph-tutorials|Working notes and runnable examples for LangChain and LangGraph.|jupyter,langchain,langgraph,tutorials,llm,agents
agent|Agent scaffolding and orchestration experiments.|typescript,ai-agents,agentic-ai,llm
ghost_ai|Interactive systems-architecture builder with real-time collaboration and background jobs.|clerk,liveblocks,nextjs,react,triggerdev,system-design,collaboration
FinSight|Financial analysis engine — ingests market data and surfaces signal.|python,finance,data-analysis,fintech,quantitative
DSlab_Project_Network_Intrusion_detection_Kirtan_Sodagar_U23CS051|Network intrusion detection using machine learning — Data Science lab project.|jupyter,machine-learning,intrusion-detection,network-security,data-science
algoX|Algorithm visualization and practice environment.|typescript,algorithms,data-structures,visualization
algotrading|Algorithmic trading strategies and backtesting in Python.|python,algorithmic-trading,quantitative-finance,backtesting,trading
Portfolio-Website|Personal portfolio website.|css,html,portfolio,website
UberClone|Ride-hailing app clone — full-stack JavaScript build.|javascript,fullstack,ride-hailing,nodejs
EmployeeManagementSystem|Employee management CRUD application.|javascript,crud,management-system,nodejs
Secrets|Authentication and secret-sharing app — session handling and password hashing.|javascript,authentication,nodejs,express,security
UrltoQr|URL-to-QR-code generator.|javascript,qrcode,url-shortener,web-app
keep|Note-taking app inspired by Google Keep.|javascript,react,notes-app,crud
ENTRIES
)

ok=0; fail=0; skipped=0; kept=0

while IFS='|' read -r repo desc topics; do
  [[ -z "${repo// }" ]] && continue

  # Read current state so we never clobber something you already wrote.
  cur=$(curl -sS -H "Authorization: Bearer $GH_TOKEN" \
        -H "Accept: application/vnd.github+json" "$API/repos/$USER/$repo")
  has_desc=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const r=JSON.parse(d);process.stdout.write(r.description?"1":"0")}catch(e){process.stdout.write("0")}})' <<< "$cur")
  has_topics=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const r=JSON.parse(d);process.stdout.write((r.topics&&r.topics.length)?"1":"0")}catch(e){process.stdout.write("0")}})' <<< "$cur")

  do_desc=1; do_topics=1
  [[ "$has_desc" == "1" && "$FORCE" != "1" ]] && do_desc=0
  [[ "$has_topics" == "1" && "$FORCE" != "1" ]] && do_topics=0

  if [[ "$do_desc" == "0" && "$do_topics" == "0" ]]; then
    echo "KEEP $repo (already has description + topics)"
    kept=$((kept+1))
    continue
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY  $repo"
    [[ "$do_desc" == "1" ]]   && echo "       + desc:   $desc"   || echo "       = desc kept"
    [[ "$do_topics" == "1" ]] && echo "       + topics: $topics" || echo "       = topics kept"
    skipped=$((skipped+1))
    continue
  fi

  d_code=200
  if [[ "$do_desc" == "1" ]]; then
    # Write the payload to a file and use --data-binary. Passing JSON with
    # non-ASCII (em dashes) through `curl -d "$var"` corrupts the UTF-8 on
    # Windows/Git Bash and GitHub rejects it with 400 "Problems parsing JSON".
    node -e 'require("fs").writeFileSync(process.argv[2],JSON.stringify({description:process.argv[1]}))' "$desc" "$TMP_PAYLOAD"
    d_code=$(curl -sS -o /dev/null -w '%{http_code}' \
      -X PATCH "$API/repos/$USER/$repo" \
      -H "Authorization: Bearer $GH_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      --data-binary "@$TMP_PAYLOAD")
  fi

  t_code=200
  if [[ "$do_topics" == "1" ]]; then
    node -e 'require("fs").writeFileSync(process.argv[2],JSON.stringify({names:process.argv[1].split(",")}))' "$topics" "$TMP_PAYLOAD"
    t_code=$(curl -sS -o /dev/null -w '%{http_code}' \
      -X PUT "$API/repos/$USER/$repo/topics" \
      -H "Authorization: Bearer $GH_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      --data-binary "@$TMP_PAYLOAD")
  fi

  if [[ "$d_code" == "200" && "$t_code" == "200" ]]; then
    echo "OK   $repo  (desc:$([[ $do_desc == 1 ]] && echo set || echo kept) topics:$([[ $do_topics == 1 ]] && echo set || echo kept))"
    ok=$((ok+1))
  else
    echo "FAIL $repo  (description:$d_code topics:$t_code)"
    fail=$((fail+1))
  fi
done <<< "$ROWS"

echo
if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run - $skipped repo(s) would change, $kept already complete. Nothing written."
else
  echo "Updated $ok repo(s), kept $kept untouched, $fail failed."
  [[ "$fail" -gt 0 ]] && echo "A 403 usually means the token is missing the 'public_repo' scope."
fi
