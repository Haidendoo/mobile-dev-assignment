"""The A01 API design; the contract is generated, not deployed."""
def contract():
    def obj(properties, required=None):
        return {"type": "object", "additionalProperties": False, "properties": properties,
                "required": required or list(properties)}
    def ref(name): return {"$ref": "#/components/schemas/"+name}
    def response(description, schema):
        return {"description":description,"content":{"application/json":{"schema":schema}}}
    def body(schema, example):
        return {"required": True,"content":{"application/json":{"schema":schema,"example":example}}}
    uid={"type":"string","format":"uuid"}
    stamp={"type":"string","format":"date-time"}
    level={"type":"string","enum":["L01","L02","L03","L04","L05"]}
    version={"type":"integer","minimum":1}
    steps={"type":"integer","minimum":1,"maximum":100000}
    elapsed={"type":"integer","minimum":0,"maximum":86400000}
    score={"p_submission_id":"20000000-0000-4000-8000-000000000001","p_level_id":"L01","p_level_version":1,"p_steps":2,"p_elapsed_ms":3200}
    schemas={
        "ScoreRequest":obj({"p_submission_id":uid,"p_level_id":level,"p_level_version":version,"p_steps":steps,"p_elapsed_ms":elapsed}),
        "ScoreReceipt":obj({"submission_id":uid,"status":{"type":"string","enum":["accepted","duplicate"]},"is_personal_best":{"type":"boolean"},"received_at":stamp}),
        "LeaderboardRequest":obj({"p_level_id":level,"p_level_version":version}),
        "LeaderboardEntry":obj({"rank":{"type":"integer","minimum":1,"maximum":20},"display_name":{"type":"string","pattern":"^Guest-[0-9A-F]{10}$"},"steps":steps,"elapsed_ms":elapsed}),
        "Leaderboard":obj({"level_id":level,"level_version":version,"generated_at":stamp,"entries":{"type":"array","maxItems":20,"items":ref("LeaderboardEntry")}}),
        "RpcError":obj({"code":{"type":"string"},"message":{"type":"string"},"details":{"type":"string","nullable":True},"hint":{"type":"string","nullable":True}}),
        "AuthSession":{"type":"object","properties":{"access_token":{"type":"string","description":"Secret runtime token; never log or commit."},"refresh_token":{"type":"string"},"token_type":{"type":"string","enum":["bearer"]},"expires_in":{"type":"integer"},"user":{"type":"object","properties":{"id":uid,"is_anonymous":{"type":"boolean"}}}},"required":["access_token","refresh_token","token_type","expires_in","user"]},
    }
    errors={str(code):response(desc,ref("RpcError")) for code,desc in [
        (400,"INVALID_ARGUMENT / PT400"),(401,"AUTH_REQUIRED / PT401; gateway auth codes may differ"),
        (403,"FORBIDDEN / PT403 or 42501"),(404,"LEVEL_NOT_FOUND / PT404"),
        (409,"IDEMPOTENCY_CONFLICT / PT409"),(429,"Provider rate limit; inspect Retry-After"),
        (500,"Temporary server error; preserve local result") ]}
    leaderboard={"level_id":"L01","level_version":1,"generated_at":"2026-10-21T08:00:05Z","entries":[{"rank":1,"display_name":"Guest-7F2A90C1D4","steps":2,"elapsed_ms":3200}]}
    receipt={"submission_id":score["p_submission_id"],"status":"accepted","is_personal_best":True,"received_at":"2026-10-21T08:00:04Z"}
    submit_response=response("Accepted or idempotent duplicate; received_at is stable",ref("ScoreReceipt"))
    submit_response["content"]["application/json"]["example"]=receipt
    rank_response=response("One best receipt per guest, at most 20 entries, stable ordering",ref("Leaderboard"))
    rank_response["content"]["application/json"]["example"]=leaderboard
    return {
        "openapi":"3.0.3",
        "info":{"title":"Forest Sokoban A01 API Design","version":"1.0.0-draft","description":"Design only. HTTPS Supabase Auth plus PostgREST JSON-object RPCs. No live project or credentials included. Rankings use steps, elapsed_ms, received_at, then submission UUID. Input score caps affect online eligibility, not offline gameplay."},
        "servers":[{"url":"https://PROJECT_REF.supabase.co","description":"Replace at A02 setup; placeholder, not deployed"}],
        "paths":{
            "/auth/v1/signup":{"post":{"operationId":"createAnonymousGuest","summary":"SDK-managed anonymous sign-in","security":[{"ProjectKey":[]}],"requestBody":body({"type":"object","maxProperties":0},{}),"responses":{"200":response("Supabase session; persist through an OS-secure adapter",ref("AuthSession")),"default":{"description":"Supabase Auth provider error; normalize to an auth error, not an RPC error"}}}},
            "/rest/v1/rpc/submit_score":{"post":{"operationId":"submitScore","summary":"Submit one completed attempt idempotently","description":"Requires Auth JWT. Derive ownership from auth.uid(); unique (guest_id, submission_id). Same payload returns original receipt; changed payload under same ID raises PT409. Return a jsonb object rather than a set-returning row array.","security":[{"ProjectKey":[],"GuestJWT":[]}],"requestBody":body(ref("ScoreRequest"),score),"responses":{"200":submit_response,**errors}}},
            "/rest/v1/rpc/get_leaderboard":{"post":{"operationId":"getLeaderboard","summary":"Public top 20 for one known level/version","description":"No auth user IDs in response. Unknown catalogue entry is PT404; known level with no receipts returns entries=[]. RPC returns one jsonb object.","security":[{"ProjectKey":[]}],"requestBody":body(ref("LeaderboardRequest"),{"p_level_id":"L01","p_level_version":1}),"responses":{"200":rank_response,**{k:v for k,v in errors.items() if k in ["400","404","429","500"]}}}},
        },
        "components":{"securitySchemes":{"ProjectKey":{"type":"apiKey","in":"header","name":"apikey","description":"Client publishable key, not a privileged service-role secret"},"GuestJWT":{"type":"http","scheme":"bearer","bearerFormat":"JWT"}},"schemas":schemas},
    }
