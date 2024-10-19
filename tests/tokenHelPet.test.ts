import { Simnet, types } from "@hirosystems/clarinet-sdk";
import { describe, expect, it } from "vitest";

const simnet = Simnet.getInstance();
const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const contractName = "tokenHelPet";

describe("tokenHelPet tests", () => {
  it("ensures simnet is well initialized", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("checks if the owner is set correctly", () => {
    const { result } = simnet.callReadOnlyFn(contractName, "get-owner", [], address1);
    expect(result).toBeOk(address1);
  });

  it("allows owner to add an agent", () => {
    const agent = accounts.get("wallet_2")!;
    const { result } = simnet.callPublicFn(contractName, "add-agent", [agent], address1);
    expect(result).toBeOk(types.string("Agente agregado con exito"));
  });

  it("checks if an address is an agent", () => {
    const agent = accounts.get("wallet_2")!;
    const { result } = simnet.callReadOnlyFn(contractName, "is-agent", [agent], address1);
    expect(result).toBeOk(types.bool(true));
  });

  it("allows agent to mint tokens", () => {
    const agent = accounts.get("wallet_2")!;
    const amount = types.uint(100);
    const { result } = simnet.callPublicFn(contractName, "mint", [amount], agent);
    expect(result).toBeOk(amount);
  });

  it("prevents non-agents from minting tokens", () => {
    const nonAgent = accounts.get("wallet_3")!;
    const amount = types.uint(100);
    const { result } = simnet.callPublicFn(contractName, "mint", [amount], nonAgent);
    expect(result).toBeErr(types.uint(403));
  });


  it("allows owner to remove an agent", () => {
    const agent = accounts.get("wallet_2")!;
    const { result } = simnet.callPublicFn(contractName, "remove-agent", [agent], address1);
    expect(result.expectOk()).toBeTruthy();
  });
});
