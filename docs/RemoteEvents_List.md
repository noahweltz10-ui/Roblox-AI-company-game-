# AI Empire Tycoon — RemoteEvents Reference

All RemoteEvents live in **ReplicatedStorage → RemoteEvents** (folder).  
`MainGameScript` creates this folder and all events automatically at server startup — you do **not** need to create them manually in Studio.

---

## Direction Key

| Symbol | Meaning |
|--------|---------|
| `S → C` | Server fires to one Client |
| `S → ALL` | Server fires to All clients (FireAllClients) |
| `C → S` | Client fires to Server |

---

## Events

### DataReady
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `DataManager.lua` (after DataStore load completes) |
| Received by | `ShopController.lua`, `MainHUD.lua` |

**Payload:** `(data: table)`

```
data = {
  Cash             = number,
  TotalEarned      = number,
  RebirthCount     = number,
  CurrentOffice    = string,          -- e.g. "Laptop"
  OwnedUpgrades    = { string, ... }, -- list of upgrade IDs
  OwnedLuxuryItems = { string, ... }, -- list of luxury item IDs
  EmployeeCount    = { [id] = count },
  HasAutoCollect   = boolean,
}
```

**Purpose:** Initialises the client with the player's full saved state on join.

---

### UpdateCash
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `IncomeManager.lua` (every income tick, ~1s) |
| Received by | `ShopController.lua`, `MainHUD.lua` |

**Payload:** `(cash: number, totalEarned: number)`

**Purpose:** Keeps the client's cash display and shop affordability checks in sync with the server.

---

### RequestIncome
| Field | Value |
|-------|-------|
| Direction | `C → S` |
| Fired by | `MainHUD.lua` (every 5 seconds) |
| Handled by | `IncomeManager.lua` |

**Payload:** *(none)*

**Purpose:** Client requests the current income-per-second value so the HUD can display it accurately.

---

### IncomeResponse
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `IncomeManager.lua` (in response to RequestIncome) |
| Received by | `MainHUD.lua` |

**Payload:** `(incomePerSecond: number)`

**Purpose:** Delivers the calculated income rate back to the requesting client.

---

### PlotAssigned
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `PlotManager.lua` (when a plot is assigned to the player) |
| Received by | `LocalInputHandler.lua` (for proximity checks), future map UI |

**Payload:** `(plotIndex: number, plotOrigin: Vector3)`

**Purpose:** Tells the client which plot is theirs and where it is in the world. Used for proximity-based UI and potential mini-map features.

---

### BuyUpgrade
| Field | Value |
|-------|-------|
| Direction | `C → S` |
| Fired by | `ShopController.lua` (via `ShopGui.lua` buy button) |
| Handled by | `IncomeManager.lua` |

**Payload:** `(upgradeId: string)`

Example values: `"Garage Office"`, `"Startup Office"`, `"Tech Campus"`, `"Skyscraper HQ"`, `"Global HQ"`

**Purpose:** Requests an office upgrade purchase. Server validates cash, ownership, and applies the upgrade.

---

### BuyEmployee
| Field | Value |
|-------|-------|
| Direction | `C → S` |
| Fired by | `ShopController.lua` (via `ShopGui.lua` hire button) |
| Handled by | `IncomeManager.lua` |

**Payload:** `(employeeId: string)`

Example values: `"Junior Dev"`, `"Senior Dev"`, `"AI Manager"`, `"CTO"`

**Purpose:** Requests hiring an employee. Server validates cash and employee slot limits.

---

### BuyLuxury
| Field | Value |
|-------|-------|
| Direction | `C → S` |
| Fired by | `ShopController.lua` (via `ShopGui.lua` buy button) |
| Handled by | `IncomeManager.lua` |

**Payload:** `(itemId: string)`

Example values: `"SportsCar"`, `"Yacht"`, `"SpaceRocket"`, `"GoldStatue"`  
*(See `LuxuryConfig.lua` for the full list of 40+ item IDs)*

**Purpose:** Requests a luxury item purchase. Server validates cash and ownership (can only buy once).

---

### PurchaseResult
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `IncomeManager.lua` (after any purchase attempt) |
| Received by | `ShopController.lua`, `ShopGui.lua` |

**Payload:** `(purchaseType: string, itemId: string, success: boolean, message: string)`

| `purchaseType` | Description |
|----------------|-------------|
| `"upgrade"` | Office upgrade purchase |
| `"employee"` | Employee hire |
| `"luxury"` | Luxury item purchase |
| `"init"` | Special case — fired after DataReady to trigger UI refresh |
| `"rebirth"` | Fired after a successful rebirth |

**Purpose:** Tells the client whether a purchase succeeded or failed and why. The shop GUI refreshes button states on every result.

---

### RebirthEligible
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `IncomeManager.lua` (when TotalEarned crosses the threshold) |
| Received by | `MainHUD.lua` |

**Payload:** `(eligible: boolean)`

**Purpose:** Tells the HUD to slide in the Rebirth button. Only fires `true` once per eligibility period (won't spam).

---

### RequestRebirth
| Field | Value |
|-------|-------|
| Direction | `C → S` |
| Fired by | `ShopController.lua` (when player clicks the Rebirth button) |
| Handled by | `IncomeManager.lua` |

**Payload:** *(none)*

**Purpose:** Player requests a rebirth. Server validates eligibility, resets progress, and fires `OnRebirth` back.

---

### RebirthResult
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `IncomeManager.lua` |
| Received by | *(currently logged; can be used for a toast notification)* |

**Payload:** `(success: boolean, message: string)`

**Purpose:** Confirmation or rejection of the rebirth request.

---

### OnRebirth
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `IncomeManager.lua` (after a successful rebirth) |
| Received by | `ShopController.lua`, `MainHUD.lua`, `ShopGui.lua` |

**Payload:** `(newRebirthCount: number)`

**Purpose:** Broadcasts the completed rebirth to all relevant client systems so they can reset their local state and UI (clear owned items, reset cash display, hide rebirth button, show updated badge).

---

### LeaderboardUpdate
| Field | Value |
|-------|-------|
| Direction | `S → ALL` |
| Fired by | `MainGameScript.lua` (every `GameConfig.LeaderboardUpdateInterval` seconds, default 10s) |
| Received by | `LeaderboardGui.lua` |

**Payload:** `(entries: table)`

```
entries = {
  [1] = { name = "PlayerName", cash = 1250000, rebirths = 2, formatted = "$1.25M" },
  [2] = { ... },
  ...  -- up to 10 entries, sorted descending by cash
}
```

**Purpose:** Delivers the current top-10 leaderboard snapshot to every client for display.

---

### OpenShop
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `MainGameScript.lua` (player steps on a shop pad) |
| Received by | `LocalInputHandler.lua`, `ShopController.lua` |

**Payload:** *(none)*

**Purpose:** Server pushes a shop-open command to the stepping player's client.

---

### CloseShop
| Field | Value |
|-------|-------|
| Direction | `S → C` |
| Fired by | `MainGameScript.lua` *(reserved for future use)* |
| Received by | `LocalInputHandler.lua` |

**Payload:** *(none)*

**Purpose:** Reserved for server-side forced shop close (e.g. when a cutscene starts or plot is lost).

---

## Adding New RemoteEvents

1. Add the name to the `REMOTE_EVENT_NAMES` table in `MainGameScript.lua`
2. Wire the server handler in the appropriate server script
3. Connect the client listener in the appropriate client script
4. Document it here

The event will be auto-created on next server start — no manual Studio work needed.
